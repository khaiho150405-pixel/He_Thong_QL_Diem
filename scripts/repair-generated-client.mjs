import { readFile, writeFile } from "node:fs/promises";

const pause = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
async function writeWithWindowsRetry(file, content) {
  for (let attempt = 1; ; attempt += 1) {
    try {
      await writeFile(file, content);
      return;
    } catch (error) {
      if (
        process.platform !== "win32" ||
        attempt >= 10 ||
        !["UNKNOWN", "EBUSY", "EPERM", "EACCES"].includes(error?.code)
      )
        throw error;
      await pause(attempt * 100);
    }
  }
}

export async function repairRecognitionMultipart() {
  const file = "packages/api_client_dart/lib/src/api/recognition_api.dart";
  const content = await readFile(file, "utf8");
  const empty =
    /    dynamic _bodyData;\r?\n\r?\n    try \{\s*\} catch\s*\(error, stackTrace\) \{/g;
  const matches = [...content.matchAll(empty)];
  if (matches.length !== 1)
    throw new Error(
      `Expected one empty recognition multipart body, found ${matches.length}`,
    );
  const form = `    dynamic _bodyData;

    try {
      final _formData = FormData();
      _formData.files.add(MapEntry(
        r'image',
        image,
      ));
      _formData.fields.add(MapEntry(
        r'componentId',
        componentId.toString(),
      ));
      // declaredRows is deprecated and optional (ADR-0015): send it only when the caller provides it.
      if (declaredRows != null) {
        _formData.fields.add(MapEntry(
          r'declaredRows',
          declaredRows.toString(),
        ));
      }
      _bodyData = _formData;
    } catch (error, stackTrace) {`;
  await writeWithWindowsRetry(file, content.replace(empty, form));
}

if (process.argv[1]?.endsWith("repair-generated-client.mjs"))
  await repairRecognitionMultipart();
