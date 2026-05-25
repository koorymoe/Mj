class QuotationItem {
  String productName;
  String unit;
  double qty;
  double price;
  String imageBase64;

  QuotationItem({
    this.productName = '',
    this.unit        = 'قطعة',
    this.qty         = 1,
    this.price       = 0,
    this.imageBase64 = '',
  });

  double get total => qty * price;

  Map<String, dynamic> toJson() => {
    'productName' : productName,
    'unit'        : unit,
    'qty'         : qty,
    'price'       : price,
    'total'       : total,
  };
}
