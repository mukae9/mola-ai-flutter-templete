import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/menu_analysis_history.dart';
import 'package:mola_gemini_flutter_template/presentation/menu_search/menu_search_page_notifier.dart';
import 'package:mola_gemini_flutter_template/presentation/menu_search/widgets/store_name_dialog.dart';

class MenuHistorySection extends StatelessWidget {
  const MenuHistorySection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<MenuSearchPageNotifier>();
    final menuAnalysisHistory = context.select(
        (MenuSearchPageState state) => state.menuAnalysisHistory);

    return Container(
      padding: const EdgeInsets.only(top: 42, left: 12, right: 12, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              '過去のメニュー解析',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 履歴がない場合のメッセージ
          if (menuAnalysisHistory.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'メニュー解析履歴はありません',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: menuAnalysisHistory.length,
              itemBuilder: (context, index) {
                final historyItem = menuAnalysisHistory[index];
                
                // 日付をフォーマット
                final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
                final formattedDate = dateFormat.format(historyItem.date);
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ExpansionTile(
                      title: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (historyItem.storeName != null)
                                  Text(
                                    historyItem.storeName!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontSize: historyItem.storeName != null ? 12 : 14,
                                    color: Colors.grey,
                                    fontWeight: historyItem.storeName != null 
                                        ? FontWeight.normal 
                                        : FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 店舗名編集ボタン
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              size: 20,
                              color: Color(0xFF1D3567),
                            ),
                            onPressed: () {
                              showStoreNameDialog(
                                context: context,
                                initialStoreName: historyItem.storeName,
                                onSave: (storeName) {
                                  notifier.setStoreName(historyItem.id, storeName);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      subtitle: Text(
                        '${historyItem.sakes.length}件の日本酒',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: historyItem.sakes.map((sake) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sake.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (sake.type != null)
                                            Text(
                                              sake.type!,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (sake.isRecommended)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: Colors.red.shade300,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.star,
                                              color: Colors.red.shade700,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'おすすめ',
                                              style: TextStyle(
                                                color: Colors.red.shade700,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
