import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mola_gemini_flutter_template/domain/repository/gemini_mola_api_repository.dart';
import 'package:state_notifier/state_notifier.dart';

import '../../domain/eintities/response/open_ai_response/open_ai_response.dart';
import '../../domain/repository/mola_api_repository.dart';

part 'main_search_page_notifier.freezed.dart';

@freezed
abstract class MainSearchPageState with _$MainSearchPageState {
  const factory MainSearchPageState({
    @Default(false) bool isLoading,
    String? sakeName,
    String? hint,
    File? sakeImage,
    String? geminiResponse,
    List<OpenAIResponse>? openAiResponseList,
  }) = _MainSearchPageState;
}

class MainSearchPageNotifier extends StateNotifier<MainSearchPageState>
    with LocatorMixin, RouteAware, WidgetsBindingObserver {
  MainSearchPageNotifier({
    required this.context,
  }) : super(const MainSearchPageState());

  final BuildContext context;
  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
  GeminiMolaApiRepository get geminiMolaApiRepository =>
      read<GeminiMolaApiRepository>();

  MolaApiRepository get molaApiRepository => read<MolaApiRepository>();

  @override
  Future<void> initState() async {
    super.initState();
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

  Future<void> promptWithText() async {
    if (state.sakeName == null) {
      return;
    }
    if (state.isLoading == true) {
      return;
    }
    state = state.copyWith(isLoading: true);
    if (state.sakeName != null) {
      final response = await molaApiRepository.promptWithTextByOpenAI(
        state.sakeName!,
      );
      state = state.copyWith(
        isLoading: false,
        sakeName: null,
      );
      state = state.copyWith(openAiResponseList: response);
    }
  }

  void setText(String text) {
    state = state.copyWith(sakeName: text);
  }
}
