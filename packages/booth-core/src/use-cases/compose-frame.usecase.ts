import { assertValidCaptureCount } from "../domain/frame";
import type {
  ComposeFrameRequest,
  ImageComposerPort,
} from "../ports/image-composer.port";

export async function composeFrameUseCase(
  composer: ImageComposerPort,
  request: ComposeFrameRequest,
) {
  assertValidCaptureCount(request.captures.length);
  return composer.composeFrame(request);
}
