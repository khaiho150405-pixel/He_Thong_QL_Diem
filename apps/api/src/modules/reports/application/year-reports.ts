import {
  BadRequestException,
  Inject,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import {
  administrator,
  currentActor,
  type Actor,
} from "../../authorization/application/policy.js";
import { slug } from "./cells.js";
import {
  YEAR_REPORT_STORE,
  type YearReportStore,
  type YearStatistics,
} from "./year-port.js";
import { yearWorkbook } from "./year-workbook.js";

function termOrder(value: unknown) {
  if (typeof value !== "string" || !/^[123]$/.test(value))
    throw new BadRequestException("Chọn học kỳ 1, 2 hoặc 3 để thống kê.");
  return Number(value);
}

function yearKey(value: number) {
  if (!Number.isSafeInteger(value) || value < 1 || value > 2147483647)
    throw new BadRequestException("Mã năm học không hợp lệ.");
  return value;
}

function contract(statistics: YearStatistics) {
  const { schoolName, ...rest } = statistics;
  void schoolName;
  return rest;
}

@Injectable()
export class YearReportsService {
  constructor(
    @Inject(YEAR_REPORT_STORE) private readonly store: YearReportStore,
  ) {}

  statistics(actor: Actor, yearId: number, term: unknown) {
    administrator(actor);
    const year = yearKey(yearId);
    const order = termOrder(term);
    return this.store.run(async (tx) => {
      await currentActor(tx.authorization, actor);
      return contract(await tx.statistics(year, order));
    });
  }

  comparison(actor: Actor, term: unknown) {
    administrator(actor);
    const order = termOrder(term);
    return this.store.run(async (tx) => {
      await currentActor(tx.authorization, actor);
      return { items: await tx.comparison(order) };
    });
  }

  export(actor: Actor, yearId: number, term: unknown) {
    administrator(actor);
    const year = yearKey(yearId);
    const order = termOrder(term);
    return this.store.run(async (tx) => {
      await currentActor(tx.authorization, actor);
      const statistics = await tx.statistics(year, order);
      const students = await tx.students(year, order);
      if (!students.length)
        throw new NotFoundException(
          "Học kỳ này chưa có dữ liệu đã công bố để xuất.",
        );
      const bytes = await yearWorkbook({
        statistics,
        term: order,
        students,
        subjects: await tx.subjects(year, order),
        exportedAt: new Date(),
      });
      await tx.recordExport(actor.id, year);
      return {
        bytes,
        filename: `tong-hop-${slug(statistics.yearName)}-hoc-ky-${order}.xlsx`,
      };
    });
  }
}
