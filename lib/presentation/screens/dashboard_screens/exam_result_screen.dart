// lib/presentation/screens/exam_result_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medi_exam/data/models/exam_result_model.dart';
import 'package:medi_exam/data/network_response.dart';
import 'package:medi_exam/data/services/exam_result_service.dart';
import 'package:medi_exam/presentation/utils/routes.dart';
import 'package:medi_exam/presentation/utils/sizes.dart';
import 'package:medi_exam/presentation/utils/app_colors.dart';
import 'package:medi_exam/presentation/widgets/common_scaffold.dart';
import 'package:medi_exam/presentation/widgets/custom_blob_background.dart';
import 'package:medi_exam/presentation/widgets/custom_glass_card.dart';
import 'package:medi_exam/presentation/widgets/loading_widget.dart';
import 'package:medi_exam/presentation/widgets/helpers/payment_screen_helpers.dart';

class ExamResultScreen extends StatefulWidget {
  const ExamResultScreen({super.key});

  @override
  State<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends State<ExamResultScreen> {
  late final Map<String, dynamic> _args;
  late final String admissionId;
  late final String examId;

  final _service = ExamResultService();

  bool _loading = true;
  String? _error;
  ExamResultModel? _model;

  @override
  void initState() {
    super.initState();
    _args = Get.arguments ?? {};
    admissionId = (_args['admissionId'] ?? '').toString();
    examId = (_args['examId'] ?? '').toString();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final NetworkResponse resp = await _service.fetchExamResult(admissionId, examId);

    if (!mounted) return;

    if (resp.isSuccess) {
      try {
        final data = resp.responseData;
        ExamResultModel? model;

        if (data is ExamResultModel) {
          model = data;
        } else if (data is Map<String, dynamic>) {
          model = ExamResultModel.fromJson(data);
        } else if (data is String) {
          final decoded = jsonDecode(data);
          if (decoded is Map<String, dynamic>) {
            model = ExamResultModel.fromJson(decoded);
          }
        }

        if (model == null) {
          setState(() {
            _loading = false;
            _error = 'Invalid response format';
          });
          return;
        }

        setState(() {
          _model = model;
          _loading = false;
        });
      } catch (e) {
        setState(() {
          _loading = false;
          _error = 'Failed to parse result: $e';
        });
      }
    } else {
      setState(() {
        _loading = false;
        _error = resp.errorMessage ?? 'Failed to load result';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: 'Exam Result',
      body: _loading
          ? const Center(child: LoadingWidget())
          : _error != null
          ? ErrorCard(message: _error!, onRetry: _load)
          : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final exam = _model?.exam;
    final res = _model?.result;
    final percent = res?.obtainedMarkPercent ?? 0.0;

    return CustomScrollView(
      slivers: [
        // Hero Section with Progress Circle
        SliverToBoxAdapter(
          child: _buildHeroSection(context, _model!, percent),
        ),

        // Info Cards Section
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 16),

              // Exam Info Card
              _buildInfoCard(
                context,
                title: 'Exam Information',
                icon: Icons.quiz_outlined,
                children: [
                  _infoRow('Exam Title', exam?.title ?? '—'),
                  _infoRow('Total Questions', _fmtInt(exam?.totalQuestion)),
                  _infoRow('Full Mark', _fmtInt(exam?.fullMark)),
                ],
              ),

              const SizedBox(height: 12),

              // Result Card
              _buildInfoCard(
                context,
                title: 'Your Performance',
                icon: Icons.analytics_outlined,
                children: [
                  _infoRow('Obtained Mark', '${_fmtDouble(res?.obtainedMark)} / ${_fmtInt(exam?.fullMark)}'),
                  _infoRow('Correct Answers', _fmtDouble(res?.correctMark)),
                  _infoRow('Negative Mark', _fmtDouble(res?.negativeMark)),
                  _infoRow('Wrong Answers', _fmtInt(res?.wrongAnswers)),
                ],
              ),

              const SizedBox(height: 12),

              // Position Card
              _buildInfoCard(
                context,
                title: 'Ranking',
                icon: Icons.leaderboard_outlined,
                children: [
                  _positionItem(
                    Icons.emoji_events_outlined,
                    'Overall Position',
                    _fmtInt(res?.overallPosition),
                    Colors.orange,
                  ),
                  _positionItem(
                    Icons.groups_outlined,
                    'Batch Position',
                    _fmtInt(res?.batchPosition),
                    Colors.blue,
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ]),
          ),
        ),

        // View Answers Button
        SliverFillRemaining(
          hasScrollBody: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildViewAnswersButton(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(BuildContext context, ExamResultModel model, double percent) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GlassCard(
        opacity: 0.20,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Progress Circle with Percentage
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: CircularProgressIndicator(
                      value: percent / 100,
                      strokeWidth: 6,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(percent),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '${_fmtDouble(percent)}%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColor.primaryTextColor,
                        ),
                      ),
                      Text(
                        'Score',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Main Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _heroStatItem(
                    Icons.check_circle_outline,
                    'Correct',
                    _fmtDouble(model.result?.correctMark),
                    Colors.green,
                  ),
                  _heroStatItem(
                    Icons.close_outlined,
                    'Wrong',
                    _fmtInt(model.result?.wrongAnswers),
                    Colors.red,
                  ),
                  _heroStatItem(
                    Icons.assignment_outlined,
                    'Obtained',
                    '${_fmtDouble(model.result?.obtainedMark)} / ${_fmtInt(model.exam?.fullMark)}',
                    Colors.blue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return CustomBlobBackground(
      backgroundColor: Colors.white,
      blobColor: AppColor.indigo,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColor.indigo.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: AppColor.indigo),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColor.primaryTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // Content
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColor.primaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _positionItem(IconData icon, String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColor.primaryTextColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildViewAnswersButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: AppColor.secondaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColor.indigo.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _onViewAnswersTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.visibility_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'View Detailed Answers',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getProgressColor(double percent) {
    if (percent >= 80) return Colors.green;
    if (percent >= 60) return Colors.yellow;
    if (percent >= 40) return Colors.orange;
    return Colors.red;
  }

  void _onViewAnswersTap() {
    final data = {
      'admissionId': admissionId.toString(),
      'examId': examId.toString(),
      'examInfo': _model?.exam,
      'result': _model?.result,
    };
    Get.toNamed(
      RouteNames.examAnswer,
      arguments: data,
      preventDuplicates: true,
    );

  }

  // Format helpers
  String _fmtInt(int? v) => v == null ? '—' : v.toString();
  String _fmtDouble(double? v) => v == null ? '—' : _trimZeros(v.toStringAsFixed(2));
  String _trimZeros(String s) => s.replaceFirst(RegExp(r'\.?0+$'), '');
}