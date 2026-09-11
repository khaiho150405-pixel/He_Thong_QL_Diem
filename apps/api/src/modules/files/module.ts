import { Global, Module, type DynamicModule } from "@nestjs/common";
import { OBJECT_STORAGE, type ObjectStorage } from "./application/port.js";
import { S3ObjectStorage } from "./infrastructure/s3-object-storage.js";

@Global()
@Module({})
export class FilesModule {
  static configure(storage?: ObjectStorage): DynamicModule {
    return {
      module: FilesModule,
      providers: [
        storage
          ? { provide: OBJECT_STORAGE, useValue: storage }
          : { provide: OBJECT_STORAGE, useClass: S3ObjectStorage },
      ],
      exports: [OBJECT_STORAGE],
    };
  }
}
