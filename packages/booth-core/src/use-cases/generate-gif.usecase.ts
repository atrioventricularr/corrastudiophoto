import type {
  GenerateGifRequest,
  GifGeneratorPort,
} from "../ports/gif-generator.port";

export async function generateGifUseCase(
  gifGenerator: GifGeneratorPort,
  request: GenerateGifRequest,
) {
  if (request.captures.length <= 0) {
    throw new Error("Cannot generate GIF without captures.");
  }

  return gifGenerator.generateGif(request);
}
