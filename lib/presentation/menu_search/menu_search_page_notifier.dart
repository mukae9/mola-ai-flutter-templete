import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mola_gemini_flutter_template/domain/repository/gemini_mola_api_repository.dart';
import 'package:state_notifier/state_notifier.dart';

import '../../common/logger.dart';
import '../../common/utils/ad_utils.dart';
import '../../common/services/background_service.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/repository/sake_menu_recognition_repository.dart';

part 'menu_search_page_notifier.freezed.dart';

@freezed
abstract class MenuSearchPageState with _$MenuSearchPageState {
  const factory MenuSearchPageState({
    @Default(false) bool isLoading,
    @Default(false) bool isExtractingInfo,
    @Default(false) bool isGettingDetails,
    @Default(false) bool isAdLoading,
    @Default(false) bool isAnalyzingInBackground,
    String? sakeName,
    String? hint,
    File? sakeImage,
    String? geminiResponse,
    @Default([]) List<Sake> extractedSakes,
    SakeMenuRecognitionResponse? sakeMenuRecognitionResponse,
    String? errorMessage,
    List<Sake>? sakes,
    @Default({}) Map<String, bool> sakeLoadingStatus,
    // 元の名前と取得した詳細情報の名前のマッピング
    @Default({}) Map<String, String> nameMapping,
    // ユーザーの好み
    String? preferences,
  }) = _MenuSearchPageState;
}

class MenuSearchPageNotifier extends StateNotifier<MenuSearchPageState>
    with LocatorMixin, RouteAware, WidgetsBindingObserver {
  MenuSearchPageNotifier({
    required this.context,
  }) : super(const MenuSearchPageState());

  final BuildContext context;
  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
  GeminiMolaApiRepository get geminiMolaApiRepository =>
      read<GeminiMolaApiRepository>();
  SakeMenuRecognitionRepository get sakeMenuRecognitionRepository =>
      read<SakeMenuRecognitionRepository>();

  @override
  Future<void> initState() async {
    super.initState();
    // final prompt2 = '今から質問をします。「日本酒のみむろ杉の特徴を教えて」';
    // final prompt =
    //     '田所酒っていう日本酒の特徴を教えてください。もしそんな日本酒が存在しないなら「該当の日本酒は存在しないようです。」と言ってください。その後似たような名前の日本酒の候補がほしいです。';
    // await requestGemini(prompt2);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {}
  }

  // ユーザーの好みを設定
  void setPreferences(String preferences) {
    state = state.copyWith(preferences: preferences);
  }

  Future<void> pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      state = state.copyWith(sakeImage: File(pickedFile.path));
    }
  }

  Future<void> pickImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      state = state.copyWith(sakeImage: File(pickedFile.path));
    }
  }

  void clearImage() {
    state = state.copyWith(
      sakeImage: null,
      extractedSakes: [],
      sakeMenuRecognitionResponse: null,
      sakes: <Sake>[],
      sakeLoadingStatus: {},
      nameMapping: {},
      errorMessage: null,
    );
  }

  /// バックグラウンド処理用のメニュー解析メソッド
  /// 
  /// このメソッドはフォアグラウンドで実行されるリポジトリメソッドを呼び出します
  /// 実際のAPI処理はリポジトリクラスに委譲します
  static Future<List<Sake>?> _backgroundMenuAnalysis(File file) async {
    try {
      if (!file.existsSync()) {
        print('File does not exist: ${file.path}');
        return null;
      }
      
      // 注意: このメソッドは実際にはバックグラウンドで実行されず、
      // フォアグラウンドでのAPI処理を開始するためのプレースホルダーとして機能します
      // 実際のAPI処理は_extractSakeInfoInForegroundメソッドで行われます
      
      // 処理中であることを示すためのダミー遅延
      await Future.delayed(Duration(milliseconds: 100));
      
      // nullを返すことで、_extractSakeInfoInForegroundメソッドが呼び出されるようにします
      return null;
    } catch (e) {
      print('Error in background menu analysis: $e');
      return null;
    }
  }

  Future<void> extractAndFetchSakeInfo(File? imageFile) async {
    if (imageFile == null) {
      return;
    }

    // 初期状態をリセット
    state = state.copyWith(
      isLoading: true,
      isExtractingInfo: true,
      errorMessage: null,
      sakes: <Sake>[],
      sakeLoadingStatus: {},
      nameMapping: {},
      isAdLoading: true,
    );

    try {
      // 広告のロードを開始
      try {
        final rewardedAd = await AdUtils.loadRewardedAd(
          onAdLoaded: (ad) {
            logger.info('リワード広告がロードされました');
          },
          onAdDismissed: () {
            logger.info('リワード広告が閉じられました');
            state = state.copyWith(isAdLoading: false);
          },
          onAdFailedToLoad: (error) {
            logger.shout('リワード広告のロードに失敗しました: ${error.message}');
            state = state.copyWith(isAdLoading: false);
          },
          onUserEarnedReward: (reward) {
            logger.info('ユーザーが報酬を獲得しました: ${reward.amount}');
          },
        );
        
        if (rewardedAd != null) {
          // バックグラウンドでメニュー解析を開始
          state = state.copyWith(isAnalyzingInBackground: true);
          
          // API処理を開始（広告表示と並行して実行）
          // 注意: 広告表示中にAPI処理を行い、広告終了後に結果を表示します
          final apiProcessing = sakeMenuRecognitionRepository.extractSakeInfo(imageFile);
          
          // 広告表示と並行してAPI処理を実行
          apiProcessing.then((extractedSakes) {
            if (extractedSakes != null && extractedSakes.isNotEmpty) {
              // 結果を処理（広告が閉じられた後に表示）
              state = state.copyWith(
                extractedSakes: extractedSakes,
                isAnalyzingInBackground: false,
                isLoading: false,
                isExtractingInfo: false,
              );
              
              // 各日本酒の読み込み状態を初期化
              final Map<String, bool> initialLoadingStatus = {};
              for (final sake in extractedSakes) {
                if (sake.name != null) {
                  initialLoadingStatus[sake.name!] = false; // false = まだ読み込んでいない
                }
              }
              
              state = state.copyWith(
                sakeLoadingStatus: initialLoadingStatus,
              );
              
              // 詳細情報の取得は広告が閉じられた後に開始
              if (!state.isAdLoading) {
                _fetchSakeDetails(extractedSakes);
              }
            } else {
              // API処理に失敗した場合
              if (!state.isAdLoading) {
                // 広告が既に閉じられている場合はエラーメッセージを表示
                state = state.copyWith(
                  isLoading: false,
                  isExtractingInfo: false,
                  isAnalyzingInBackground: false,
                  errorMessage: '日本酒情報を抽出できませんでした',
                );
              }
            }
          }).catchError((e) {
            logger.shout('API処理でエラーが発生しました: $e');
            if (!state.isAdLoading) {
              // 広告が既に閉じられている場合はエラーメッセージを表示
              state = state.copyWith(
                isLoading: false,
                isExtractingInfo: false,
                isAnalyzingInBackground: false,
                errorMessage: '日本酒情報の抽出に失敗しました: $e',
              );
            }
          });
          
          // 広告を表示
          try {
            await AdUtils.showRewardedAd(
              rewardedAd,
              onUserEarnedReward: (reward) {
                logger.info('ユーザーが報酬を獲得しました: ${reward.amount}');
              },
            );
            
            // 広告が閉じられた後、APIの結果が既に取得されていれば詳細情報を取得
            if (!state.isAnalyzingInBackground && state.extractedSakes.isNotEmpty) {
              _fetchSakeDetails(state.extractedSakes);
            }
          } catch (e) {
            logger.shout('広告の表示に失敗しました: $e');
            // 広告の表示に失敗した場合も、バックグラウンド処理は続行
          }
          
          return; // バックグラウンド処理を開始したので、ここで終了
        }
      } catch (e) {
        logger.shout('広告処理でエラーが発生しました: $e');
        state = state.copyWith(isAdLoading: false);
      }
      
      // 広告のロードに失敗した場合や広告がnullの場合は、通常の処理を続行
      await _extractSakeInfoInForeground(imageFile);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isExtractingInfo: false,
        isGettingDetails: false,
        isAdLoading: false,
        errorMessage: '日本酒情報の抽出に失敗しました: $e',
      );
    }
  }
  
  /// 日本酒の詳細情報を取得する
  Future<void> _fetchSakeDetails(List<Sake> extractedSakes) async {
    if (extractedSakes.isEmpty) return;
    
    try {
      // 詳細情報の取得を開始
      state = state.copyWith(isGettingDetails: true);
      
      for (final extractedSake in extractedSakes) {
        try {
          final sakeName = extractedSake.name;
          final sakeType = extractedSake.type;
          
          if (sakeName != null && sakeName.isNotEmpty) {
            // この日本酒の読み込み状態を「読み込み中」に設定
            final updatedLoadingStatus =
                Map<String, bool>.from(state.sakeLoadingStatus);
            updatedLoadingStatus[sakeName] = true; // true = 読み込み中
            state = state.copyWith(sakeLoadingStatus: updatedLoadingStatus);
            
            logger.info('日本酒情報を取得中: $sakeName');
            final sakeInfo = await sakeMenuRecognitionRepository.getSakeInfo(
              sakeName,
              type: sakeType,
              preferences: state.preferences ?? '甘口でフルーティ',
            );
            
            // 読み込み状態を更新（成功または失敗）
            final newLoadingStatus =
                Map<String, bool>.from(state.sakeLoadingStatus);
            newLoadingStatus[sakeName] = false; // 読み込み完了
            
            if (sakeInfo != null) {
              // 名前のマッピングを更新（元の名前 -> 取得した詳細情報の名前）
              final newNameMapping =
                  Map<String, String>.from(state.nameMapping);
              newNameMapping[sakeName] = sakeInfo.name ?? sakeName;
              
              // 現在のsakesリストに新しい情報を追加
              final List<Sake> currentSakes = state.sakes ?? [];
              final List<Sake> updatedSakes = [...currentSakes, sakeInfo];
              state = state.copyWith(
                sakes: updatedSakes,
                sakeLoadingStatus: newLoadingStatus,
                nameMapping: newNameMapping,
              );
            } else {
              // 詳細情報の取得に失敗した場合も状態を更新
              state = state.copyWith(sakeLoadingStatus: newLoadingStatus);
            }
          }
        } catch (e) {
          // 個別の日本酒情報取得に失敗しても続行
          final sakeName = extractedSake.name;
          if (sakeName != null) {
            final updatedLoadingStatus =
                Map<String, bool>.from(state.sakeLoadingStatus);
            updatedLoadingStatus[sakeName] = false; // 読み込み完了（エラー）
            state = state.copyWith(sakeLoadingStatus: updatedLoadingStatus);
          }
          logger.shout('日本酒情報の取得に失敗: ${extractedSake.name}, エラー: $e');
        }
      }
      
      // すべての詳細情報の取得が完了
      state = state.copyWith(isGettingDetails: false);
    } catch (e) {
      logger.shout('詳細情報の取得中にエラーが発生しました: $e');
      state = state.copyWith(
        isGettingDetails: false,
        errorMessage: '日本酒の詳細情報の取得に失敗しました',
      );
    }
  }
  
  /// フォアグラウンドでメニュー解析を実行する
  Future<void> _extractSakeInfoInForeground(File imageFile) async {
    try {
      // 画像から日本酒情報を抽出（直接List<Sake>を取得）
      final extractedSakes =
          await sakeMenuRecognitionRepository.extractSakeInfo(imageFile);
      
      if (extractedSakes == null || extractedSakes.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          isExtractingInfo: false,
          isAdLoading: false,
          isAnalyzingInBackground: false,
          errorMessage: '日本酒情報を抽出できませんでした',
        );
        return;
      }
      
      // 抽出した日本酒情報を表示用に保存し、ローディングを終了
      // 各日本酒の読み込み状態を初期化
      final Map<String, bool> initialLoadingStatus = {};
      for (final sake in extractedSakes) {
        if (sake.name != null) {
          initialLoadingStatus[sake.name!] = false; // false = まだ読み込んでいない
        }
      }
      
      state = state.copyWith(
        isLoading: false,
        isExtractingInfo: false,
        isAdLoading: false,
        isAnalyzingInBackground: false,
        extractedSakes: extractedSakes,
        sakeLoadingStatus: initialLoadingStatus,
      );
      
      // 詳細情報を取得
      await _fetchSakeDetails(extractedSakes);
    } catch (e) {
      logger.shout('メニュー解析中にエラーが発生しました: $e');
      state = state.copyWith(
        isLoading: false,
        isExtractingInfo: false,
        isGettingDetails: false,
        isAdLoading: false,
        isAnalyzingInBackground: false,
        errorMessage: '日本酒情報の抽出に失敗しました: $e',
      );
    }
  }
}
