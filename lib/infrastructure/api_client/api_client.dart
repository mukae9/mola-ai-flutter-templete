import 'package:chopper/chopper.dart';

import '../../domain/eintities/request/favorite_body.dart';

part 'api_client.chopper.dart';

@ChopperApi(baseUrl: '/')
abstract class ApiClient extends ChopperService {
  static ApiClient create([ChopperClient? client]) => _$ApiClient(client);

  @Get(path: 'check_api_use_count')
  Future<Response> checkApiUseCount();

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

  @Post(path: 'prompt_with_image_by_open_ai')
  @Multipart()
  Future<Response> promptWithImageByOpenAI(
    @Part() String image,
    @Part() String hint,
  );

  @Get(path: 'prompt_with_favorite')
  @Multipart()
  Future<Response> promptWithFavorite(
    @Body() FavoriteBody body,
  );
}
