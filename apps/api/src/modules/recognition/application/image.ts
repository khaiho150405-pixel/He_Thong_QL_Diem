import { BadRequestException } from "@nestjs/common";

export const MAX_IMAGE_BYTES = 10 * 1024 * 1024;
const MAX_DIMENSION = 10_000;
const MAX_PIXELS = 40_000_000;

export interface InspectedImage {
  contentType: "image/png" | "image/jpeg";
  extension: "png" | "jpg";
  width: number;
  height: number;
}

function pngSize(bytes: Uint8Array): [number, number] | null {
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];
  if (
    bytes.length < 24 ||
    signature.some((value, index) => bytes[index] !== value) ||
    String.fromCharCode(...bytes.slice(12, 16)) !== "IHDR"
  )
    return null;
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  return [view.getUint32(16), view.getUint32(20)];
}

function jpegSize(bytes: Uint8Array): [number, number] | null {
  if (
    bytes.length < 4 ||
    bytes[0] !== 0xff ||
    bytes[1] !== 0xd8 ||
    bytes.at(-2) !== 0xff ||
    bytes.at(-1) !== 0xd9
  )
    return null;
  let offset = 2;
  while (offset + 8 < bytes.length) {
    if (bytes[offset] !== 0xff) return null;
    const marker = bytes[offset + 1]!;
    offset += 2;
    if (marker === 0xd8 || marker === 0xd9) continue;
    if (offset + 2 > bytes.length) return null;
    const length = (bytes[offset]! << 8) | bytes[offset + 1]!;
    if (length < 2 || offset + length > bytes.length) return null;
    if (
      [
        0xc0, 0xc1, 0xc2, 0xc3, 0xc5, 0xc6, 0xc7, 0xc9, 0xca, 0xcb, 0xcd, 0xce,
        0xcf,
      ].includes(marker)
    ) {
      return [
        (bytes[offset + 5]! << 8) | bytes[offset + 6]!,
        (bytes[offset + 3]! << 8) | bytes[offset + 4]!,
      ];
    }
    offset += length;
  }
  return null;
}

export function inspectImage(
  bytes: Uint8Array,
  claimedType: string,
): InspectedImage {
  if (!bytes.length || bytes.byteLength > MAX_IMAGE_BYTES)
    throw new BadRequestException();
  const png = pngSize(bytes);
  const jpeg = png ? null : jpegSize(bytes);
  if (!png && !jpeg) throw new BadRequestException();
  const [width, height] = png ?? jpeg!;
  const contentType = png ? "image/png" : "image/jpeg";
  if (
    claimedType !== contentType ||
    width < 1 ||
    height < 1 ||
    width > MAX_DIMENSION ||
    height > MAX_DIMENSION ||
    width * height > MAX_PIXELS
  )
    throw new BadRequestException();
  return {
    contentType,
    extension: png ? "png" : "jpg",
    width,
    height,
  };
}
