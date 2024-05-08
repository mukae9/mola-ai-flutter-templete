import 'package:chopper/chopper.dart';

part 'api_client.chopper.dart';

@ChopperApi(baseUrl: '/')
abstract class ApiClient extends ChopperService {
  static ApiClient create([ChopperClient? client]) => _$ApiClient(client);

  @Get(path: 'prompt_with_text')
  Future<Response> promptWithText(
    @Body() Map<String, String> text,
  );

  @Post(path: 'prompt_with_image')
  @Multipart()
  Future<Response> promptWithImage(
    @Part() String image,
    @Part() String hint,
  );
}