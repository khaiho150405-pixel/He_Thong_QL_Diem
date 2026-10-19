export interface RecognitionOutboxEvent {
  id: string;
  /** Phiếu của sự kiện. Với sự kiện lô: phiếu đại diện (cột mẫu đứng đầu), chỉ để ghi log; việc xử lý theo `batchId`. */
  ticketId: string;
  /** Có mặt khi là sự kiện của cả lô nhiều trang (ADR-0016): MỘT sự kiện cho mọi phiếu của lô. */
  batchId?: string;
  jobId: string;
  attempts: number;
}

export interface RecognitionOutbox {
  claim(limit: number): Promise<RecognitionOutboxEvent[]>;
  published(eventId: string): Promise<void>;
  failed(eventId: string, errorCode: string): Promise<void>;
}

export interface RecognitionQueue {
  enqueue(event: RecognitionOutboxEvent): Promise<void>;
  close(): Promise<void>;
}

export class RecognitionDispatcher {
  constructor(
    private readonly outbox: RecognitionOutbox,
    private readonly queue: RecognitionQueue,
  ) {}

  async dispatchOnce(): Promise<number> {
    const events = await this.outbox.claim(10);
    for (const event of events) {
      try {
        await this.queue.enqueue(event);
        await this.outbox.published(event.id);
      } catch (error) {
        const code = error instanceof Error ? error.name : "QUEUE_ERROR";
        await this.outbox.failed(event.id, code);
      }
    }
    return events.length;
  }

  async run(signal: AbortSignal): Promise<void> {
    while (!signal.aborted) {
      const count = await this.dispatchOnce();
      if (count === 0)
        await new Promise<void>((resolve) => {
          const timer = setTimeout(resolve, 1000);
          signal.addEventListener(
            "abort",
            () => {
              clearTimeout(timer);
              resolve();
            },
            { once: true },
          );
        });
    }
  }

  close(): Promise<void> {
    return this.queue.close();
  }
}
