import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:ntu_successsprint_adminpanel/constant.dart';
import 'package:url_launcher/url_launcher.dart';

class FirebaseListView extends StatelessWidget {
  final String? selectedPath;
  final DatabaseReference database;
  final String? fieldKey;
  final String? languageKey;
  final String? urlKey;
  final String? transcriptKey;
  final String emptyMessage;
  final IconData leadingIcon;
  final Color iconColor;

  const FirebaseListView({
    Key? key,
    required this.selectedPath,
    required this.database,
    this.fieldKey,
    this.languageKey,
    this.urlKey,
    this.transcriptKey,
    required this.emptyMessage,
    required this.leadingIcon,
    required this.iconColor,
  }) : super(key: key);

  void _showTranscriptDialog(
      BuildContext context, String title, String transcript) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: SizedBox(width: 400, child: Text("Transcript for $title")),
          content: SizedBox(
              width: 400,
              child: SingleChildScrollView(child: Text(transcript))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text("Cancel", style: TextStyle(color: secondaryColor)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (selectedPath == null) {
      return Center(child: Text(emptyMessage));
    }

    return StreamBuilder<DatabaseEvent>(
      stream: database.child(selectedPath!).onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return Center(child: Text('No data available'));
        }

        Map<dynamic, dynamic>? data =
            snapshot.data!.snapshot.value as Map<dynamic, dynamic>?;
        List<Map<String, String>> itemList = [];

        if (data != null) {
          final sortedEntries = data.entries.toList()
            ..sort((a, b) {
              final aSeq = (a.value['sequence'] ?? 0);
              final bSeq = (b.value['sequence'] ?? 0);
              return (aSeq is num
                      ? aSeq
                      : double.tryParse(aSeq.toString()) ?? 0)
                  .compareTo(bSeq is num
                      ? bSeq
                      : double.tryParse(bSeq.toString()) ?? 0);
            });

          for (var entry in sortedEntries) {
            final value = entry.value;
            String? title =
                fieldKey != null ? value[fieldKey]?.toString() : null;
            String? url = urlKey != null ? value[urlKey]?.toString() : null;
            String? transcript =
                transcriptKey != null ? value[transcriptKey]?.toString() : null;
            String? language =
                languageKey != null ? value[languageKey]?.toString() : null;

            itemList.add({
              "title": title ?? "",
              "url": url ?? "",
              "transcript": transcript ?? "",
              "language": language ?? "",
            });
          }
        }

        return ListView.separated(
          itemCount: itemList.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            String title = itemList[index]["title"]!;
            String url = itemList[index]["url"]!;
            String transcript = itemList[index]["transcript"]!;
            String language = itemList[index]["language"]!;

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(leadingIcon, color: iconColor),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title.isNotEmpty ? title : 'Untitled',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      if (language.isNotEmpty)
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: primaryColor.withOpacity(0.2)),
                          ),
                          child: Text(
                            language,
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  if (url.isNotEmpty)
                    InkWell(
                      onTap: () async {
                        Uri uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, webOnlyWindowName: '_blank');
                        }
                      },
                      child: Text(
                        url,
                        style: TextStyle(color: secondaryColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 5),
                  if (transcript.isNotEmpty)
                    InkWell(
                      onTap: () {
                        _showTranscriptDialog(context, title, transcript);
                      },
                      child: Text(
                        "[View Transcript]",
                        style: TextStyle(
                          color: primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
          separatorBuilder: (BuildContext context, int index) {
            return const Divider();
          },
        );
      },
    );
  }
}
