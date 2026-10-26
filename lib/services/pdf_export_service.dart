import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/hvac_models.dart';

class PdfExportService {
  PdfExportService._();
  static final PdfExportService instance = PdfExportService._();

  Future<void> exportJobSheet({
    required CalculationResult result,
    required String jobName,
    required String clientLocation,
    required String technicianName,
  }) async {
    final pdf = pw.Document();
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blueGrey900,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'HVAC DUCT SIZING & AIRFLOW SPECIFICATION',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Compliant with ASHRAE Fundamentals & European EN 1505/1506',
                          style: const pw.TextStyle(
                              color: PdfColors.teal100, fontSize: 10),
                        ),
                      ],
                    ),
                    pw.Text(
                      'JOB SHEET',
                      style: pw.TextStyle(
                        color: PdfColors.tealAccent,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Job / Project Name: $jobName',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold)),
                        pw.Text('Client Location: $clientLocation'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Date: $formattedDate'),
                        pw.Text('Engineer / Tech: $technicianName'),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'PRIMARY DUCT SIZING RESULTS',
                style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey800),
              ),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Parameter',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Imperial (ASHRAE)',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Metric (EN 1506)',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Design Airflow (Q)')),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('${result.airflowCfm.round()} CFM')),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                              '${result.airflowLs.toStringAsFixed(1)} L/s (${result.airflowM3h.round()} m³/h)')),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Design Velocity (V)')),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('${result.velocityFpm.round()} fpm')),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                              '${result.velocityMs.toStringAsFixed(1)} m/s')),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Calculated Free Area')),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('${result.areaSqFt} sq ft')),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('${result.areaSqM} m²')),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Standard Round Duct Ø')),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                              '${result.standardRoundDiameterIn}" (Exact: ${result.exactRoundDiameterIn}")')),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                              '${result.standardRoundDiameterMm.round()} mm (Exact: ${result.exactRoundDiameterMm.round()} mm)')),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Rectangular Equivalent (Huebscher)')),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                              '${result.rectWidthIn}" W x ${result.rectHeightIn}" H (Ratio ${result.aspectRatio}:1)')),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                              '${result.rectWidthMm.round()} mm W x ${result.rectHeightMm.round()} mm H')),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Friction Loss Rate')),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                              '${result.frictionLossPer100FtInWg} in. wg / 100 ft')),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child:
                              pw.Text('${result.frictionLossPerMPa} Pa / m')),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Velocity Pressure (Pv)')),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child:
                              pw.Text('${result.velocityPressureInWg} in. wg')),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('${result.velocityPressurePa} Pa')),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Recommended Sheet Gauge')),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                              'SMACNA: ${result.recommendedGaugeSMACNA}')),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                              'DW144: ${result.recommendedGaugeDW144}')),
                    ],
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                          width: 180,
                          decoration: const pw.BoxDecoration(
                              border: pw.Border(top: pw.BorderSide()))),
                      pw.SizedBox(height: 4),
                      pw.Text('Installing Technician Signature',
                          style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                          width: 180,
                          decoration: const pw.BoxDecoration(
                              border: pw.Border(top: pw.BorderSide()))),
                      pw.SizedBox(height: 4),
                      pw.Text('Client / Inspector Acceptance',
                          style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'HVAC_Job_Sheet_${jobName.replaceAll(" ", "_")}.pdf',
    );
  }

  Future<void> exportScheduleSheet({
    required List<DuctSegment> segments,
    required String projectName,
    required String engineerName,
  }) async {
    final pdf = pw.Document();
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blueGrey900,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'MULTI-SEGMENT DUCTWORK SCHEDULE',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Project Air Distribution Schedule & Sheet Metal Takeoff',
                          style: const pw.TextStyle(
                              color: PdfColors.teal100, fontSize: 10),
                        ),
                      ],
                    ),
                    pw.Text(
                      'SCHEDULE SHEET',
                      style: pw.TextStyle(
                        color: PdfColors.tealAccent,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text('Project: $projectName • Engineer: $engineerName • Date: $formattedDate',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 14),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Segment Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Airflow', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Velocity', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Rect Size / Ø', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Friction', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Gauge (SMACNA)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                    ],
                  ),
                  ...segments.map((seg) {
                    final res = seg.result;
                    final sizeStr = res.shape == DuctShape.round
                        ? '${res.standardRoundDiameterIn}" Ø (${res.standardRoundDiameterMm.round()} mm)'
                        : '${res.rectWidthIn}"x${res.rectHeightIn}" (${res.rectWidthMm.round()}x${res.rectHeightMm.round()} mm)';

                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(seg.name, style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${res.airflowCfm.round()} CFM / ${res.airflowLs.round()} L/s', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${res.velocityFpm.round()} fpm / ${res.velocityMs.toStringAsFixed(1)} m/s', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(sizeStr, style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${res.frictionLossPer100FtInWg} in.wg', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(res.recommendedGaugeSMACNA, style: const pw.TextStyle(fontSize: 9))),
                      ],
                    );
                  }),
                ],
              ),
              pw.Spacer(),
              pw.Divider(color: PdfColors.grey300),
              pw.Text('Generated by HVAC Duct Sizing & Airflow Calculator', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Duct_Schedule_${projectName.replaceAll(" ", "_")}.pdf',
    );
  }
}
