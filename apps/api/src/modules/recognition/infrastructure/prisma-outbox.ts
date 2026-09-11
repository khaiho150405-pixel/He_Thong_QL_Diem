import type { PrismaClient } from "../../../generated/prisma/client.js";
import type {
  RecognitionOutbox,
  RecognitionOutboxEvent,
} from "../application/outbox.js";

interface OutboxRow {
  id: string;
  ticketId: string;
  jobId: string;
  attempts: number;
}

export class PrismaRecognitionOutbox implements RecognitionOutbox {
  constructor(private readonly db: PrismaClient) {}

  claim(limit: number): Promise<RecognitionOutboxEvent[]> {
    return this.db.$queryRaw<OutboxRow[]>`
      WITH picked AS (
        SELECT ma_su_kien FROM public.recognition_outbox
        WHERE da_gui_luc IS NULL AND so_lan_thu < 5
          AND san_sang_luc <= statement_timestamp()
          AND (khoa_den IS NULL OR khoa_den < statement_timestamp())
        ORDER BY ma_su_kien
        FOR UPDATE SKIP LOCKED
        LIMIT ${limit}::integer
      )
      UPDATE public.recognition_outbox o
      SET khoa_den=statement_timestamp()+interval '30 seconds',
          so_lan_thu=o.so_lan_thu+1
      FROM picked WHERE o.ma_su_kien=picked.ma_su_kien
      RETURNING o.ma_su_kien::text AS id,
        o.du_lieu->>'ticketId' AS "ticketId",
        o.du_lieu->>'jobId' AS "jobId",
        o.so_lan_thu AS attempts`;
  }

  async published(eventId: string): Promise<void> {
    await this.db
      .$executeRaw`SELECT public.xac_nhan_outbox(${BigInt(eventId)}::bigint)`;
  }

  async failed(eventId: string, errorCode: string): Promise<void> {
    await this.db
      .$executeRaw`SELECT public.that_bai_outbox(${BigInt(eventId)}::bigint,${errorCode}::text)`;
  }
}
