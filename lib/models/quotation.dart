import 'quotation_item.dart';

class Quotation {
  String quotationNumber;
  String date;
  String duration;
  String customerName;
  String customerPhone;
  String customerAddress;
  String projectName;
  List<QuotationItem> items;
  double discountPercent;
  String notes;

  Quotation({
    this.quotationNumber = '',
    this.date            = '',
    this.duration        = '',
    this.customerName    = '',
    this.customerPhone   = '',
    this.customerAddress = '',
    this.projectName     = '',
    List<QuotationItem>? items,
    this.discountPercent = 0,
    this.notes           = '',
  }) : items = items ?? [QuotationItem()];

  double get grandTotal    => items.fold(0.0, (s, i) => s + i.total);
  double get discountValue => grandTotal * discountPercent / 100;
  double get netTotal      => grandTotal - discountValue;

  Map<String, dynamic> toJson() => {
    'customerName'    : customerName,
    'customerPhone'   : customerPhone,
    'customerAddress' : customerAddress,
    'projectName'     : projectName,
    'duration'        : duration,
    'items'           : items.map((i) => i.toJson()).toList(),
    'grandTotal'      : grandTotal,
    'discountPercent' : discountPercent,
    'discountValue'   : discountValue,
    'netTotal'        : netTotal,
    'notes'           : notes,
  };
}
