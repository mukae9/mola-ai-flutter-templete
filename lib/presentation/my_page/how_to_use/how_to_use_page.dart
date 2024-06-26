import 'package:flutter/material.dart';

class HowToUse extends StatelessWidget {
  const HowToUse({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D3567),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: const Color(0xFF1D3567),
        child: Column(
          children: [
            Text(
              'SAKEPEDIA利用規約',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(
              height: 40,
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'SAKEPEDIAはGoogle llcが提供するAIを利用した日本酒特化型のアプリです。以下の内容に抵触する場合サービスがご利用いただけなくなる場合があります。\n\n・不必要な回数のリクエストを送る\n・生成されたデータの商用利用\n・その他Google LLCが定める規約の違反\n',
                style: TextStyle(color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'また、利用するAIの状況によっては応答しない、誤情報、信憑性が疑わしい情報が回答されるなどが発生する可能性がありますが、ユーザーの不都合について開発陣は一切の責任を負いません。ご了承ください。',
                style: TextStyle(color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                '以上をご承諾の上、SAKEPEDIAを楽しく使っていただけたらと思います。',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
