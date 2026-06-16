import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfService {
  // ─── Color Palette ───────────────────────────────────────────────
  static final _accentDark  = PdfColor.fromHex('#3D4A33');
  static final _accentMid   = PdfColor.fromHex('#5E6B52');
  static final _accentLight = PdfColor.fromHex('#7A8C6A');
  static final _bgLight     = PdfColor.fromHex('#F7F8F5');
  static final _bgBorder    = PdfColor.fromHex('#E4E8DF');
  static final _dark        = PdfColor.fromHex('#2C3327');
  static final _grey        = PdfColor.fromHex('#70786C');
  static final _green       = PdfColor.fromHex('#2E7D32');
  static final _greenLight  = PdfColor.fromHex('#E8F5E9');
  static final _white       = PdfColors.white;

  // ─── Format helpers ──────────────────────────────────────────────
  static String _formatRupiah(int value) {
    final formatter = NumberFormat.decimalPattern('id_ID');
    return 'Rp ${formatter.format(value)}';
  }

  static String _formatDate(DateTime dt) {
    return DateFormat('dd MMMM yyyy', 'id_ID').format(dt);
  }

  // ─── Main entry point ────────────────────────────────────────────
  static Future<void> generateAndPrintReceipt({
    required Map<String, dynamic> hotel,
    required String selectedRoom,
    required String name,
    required String email,
    required String phone,
    required String paymentMethod,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int guest,
    required String bookingCode,
  }) async {
    final pdf = pw.Document();

    final int nights   = checkOutDate.difference(checkInDate).inDays;
    final int duration = nights <= 0 ? 1 : nights;

    // Parse room price (handles "Rp 500.000" or plain "500000")
    final rawPrice = hotel['price']?.toString() ?? '0';
    final cleanPrice = rawPrice
        .replaceAll(RegExp(r'[Rp\s]'), '')
        .replaceAll('.', '')
        .replaceAll(',', '');
    final int roomPrice  = int.tryParse(cleanPrice) ?? 0;
    final int subtotal   = roomPrice * duration;
    final int taxAndFee  = (subtotal * 0.1).round();
    final int grandTotal = subtotal + taxAndFee;

    final hotelName  = hotel['title'] ?? hotel['name'] ?? 'Hotel';
    final issuedStr  = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());
    final checkInStr  = _formatDate(checkInDate);
    final checkOutStr = _formatDate(checkOutDate);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ── Banner Header ──────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    colors: [_accentDark, _accentMid, _accentLight],
                    begin: pw.Alignment.topLeft,
                    end: pw.Alignment.bottomRight,
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    // Logo
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'RESTIFY',
                          style: pw.TextStyle(
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                            color: _white,
                            letterSpacing: 2,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Your Trusted Hotel Booking Partner',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontStyle: pw.FontStyle.italic,
                            color: PdfColor.fromHex('#C8D4C0'),
                          ),
                        ),
                      ],
                    ),
                    // Receipt tag
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColor.fromHex('#FFFFFF60'), width: 1.5),
                            borderRadius: pw.BorderRadius.circular(20),
                            color: PdfColor.fromHex('#FFFFFF26'),
                          ),
                          child: pw.Text(
                            'E-RECEIPT',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: _white,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          'No. Transaksi: $bookingCode',
                          style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('#C8D4C0')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Status Strip ───────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                color: _bgLight,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('STATUS PEMBAYARAN',
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _grey, letterSpacing: 1)),
                        pw.SizedBox(height: 5),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: _greenLight,
                            border: pw.Border.all(color: PdfColor.fromHex('#81C784'), width: 1.5),
                            borderRadius: pw.BorderRadius.circular(20),
                          ),
                          child: pw.Text(
                            '✓  LUNAS / TERBAYAR',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _green),
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('TANGGAL DITERBITKAN',
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _grey, letterSpacing: 1)),
                        pw.SizedBox(height: 5),
                        pw.Text(issuedStr,
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _dark)),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Body ───────────────────────────────────────────
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(32),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Two-column: Pemesan & Reservasi
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Pemesan
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                _sectionHeader('DETAIL PEMESAN'),
                                pw.SizedBox(height: 8),
                                _infoRow('Nama', name),
                                _infoRow('Email', email),
                                _infoRow('Telepon', phone.isEmpty ? '-' : phone),
                              ],
                            ),
                          ),
                          pw.SizedBox(width: 24),
                          // Reservasi
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                _sectionHeader('DETAIL RESERVASI'),
                                pw.SizedBox(height: 8),
                                _infoRow('Hotel', hotelName),
                                _infoRow('Tipe Kamar', selectedRoom),
                                _infoRow('Check-in', checkInStr),
                                _infoRow('Check-out', checkOutStr),
                                _infoRow('Durasi', '$duration Malam'),
                                _infoRow('Jumlah Tamu', '$guest Orang'),
                              ],
                            ),
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 24),

                      // Payment Table
                      _sectionHeader('RINCIAN PEMBAYARAN'),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: _bgBorder),
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Table(
                          columnWidths: {
                            0: const pw.FlexColumnWidth(3.5),
                            1: const pw.FlexColumnWidth(1.5),
                            2: const pw.FlexColumnWidth(1),
                            3: const pw.FlexColumnWidth(2),
                          },
                          children: [
                            // Header
                            pw.TableRow(
                              decoration: pw.BoxDecoration(
                                color: _accentMid,
                                borderRadius: const pw.BorderRadius.only(
                                  topLeft: pw.Radius.circular(8),
                                  topRight: pw.Radius.circular(8),
                                ),
                              ),
                              children: [
                                _tableHeader('Deskripsi Layanan'),
                                _tableHeader('Harga / Malam'),
                                _tableHeader('Durasi'),
                                _tableHeader('Subtotal'),
                              ],
                            ),
                            // Row
                            pw.TableRow(
                              decoration: pw.BoxDecoration(color: _bgLight),
                              children: [
                                _tableCell('$selectedRoom\n$hotelName', isDesc: true),
                                _tableCell(_formatRupiah(roomPrice)),
                                _tableCell('$duration Malam'),
                                _tableCell(_formatRupiah(subtotal), isRight: true),
                              ],
                            ),
                          ],
                        ),
                      ),

                      pw.SizedBox(height: 16),

                      // Totals
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              _totalRow('Subtotal', _formatRupiah(subtotal)),
                              pw.SizedBox(height: 4),
                              _totalRow('Pajak & Biaya (10%)', _formatRupiah(taxAndFee)),
                              pw.SizedBox(height: 6),
                              pw.Container(width: 280, height: 1.5, color: _bgBorder),
                              pw.SizedBox(height: 6),
                              // Grand Total box
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: pw.BoxDecoration(
                                  gradient: pw.LinearGradient(
                                    colors: [_accentDark, _accentMid],
                                    begin: pw.Alignment.topLeft,
                                    end: pw.Alignment.bottomRight,
                                  ),
                                  borderRadius: pw.BorderRadius.circular(10),
                                ),
                                child: pw.Row(
                                  children: [
                                    pw.Text(
                                      'GRAND TOTAL    ',
                                      style: pw.TextStyle(
                                        fontSize: 12,
                                        fontWeight: pw.FontWeight.bold,
                                        color: _white,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    pw.Text(
                                      _formatRupiah(grandTotal),
                                      style: pw.TextStyle(
                                        fontSize: 18,
                                        fontWeight: pw.FontWeight.bold,
                                        color: _white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Footer ────────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                color: _bgLight,
                child: pw.Column(
                  children: [
                    pw.Divider(color: _bgBorder, height: 1),
                    pw.SizedBox(height: 12),
                    pw.Center(
                      child: pw.Text(
                        'Terima kasih telah memilih Restify! Semoga menginap Anda menyenangkan.',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _accentDark),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Center(
                      child: pw.Text(
                        'Tunjukkan e-receipt ini kepada resepsionis saat check-in.',
                        style: pw.TextStyle(fontSize: 8, color: _grey),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Center(
                      child: pw.Text(
                        'Dokumen diterbitkan secara digital oleh sistem Restify. © 2025 Restify. Seluruh hak cipta dilindungi.',
                        style: pw.TextStyle(fontSize: 7, color: PdfColor.fromHex('#9AA395')),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Restify_Receipt_$bookingCode.pdf',
    );
  }

  // ─── Widget Helpers ─────────────────────────────────────────────

  static pw.Widget _sectionHeader(String text) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#5E6B52'),
            letterSpacing: 1.2,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Container(height: 1.5, color: PdfColor.fromHex('#E4E8DF')),
      ],
    );
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('#70786C')),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(9),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _tableCell(String text, {bool isRight = false, bool isDesc = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(9),
      child: pw.Text(
        text,
        textAlign: isRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: isDesc ? 8 : 9,
          fontWeight: isRight ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isDesc ? PdfColor.fromHex('#4A5240') : PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _totalRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#70786C'))),
        pw.SizedBox(width: 24),
        pw.SizedBox(
          width: 160,
          child: pw.Text(
            value,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
