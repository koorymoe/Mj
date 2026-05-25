// ============================================
// نظام عرض السعر الرسمي - شركة الأماني
// Code.gs — مُحدَّث: إصلاح الأخطاء + API الموبايل
// ============================================

const SHEET_NAME          = 'عروض_الاسعار';
const PRODUCTS_SHEET_NAME = 'قاعدة_المنتجات';
const IMAGES_FOLDER_NAME  = 'أماني_صور_المنتجات';

// ============================================
// الواجهة الرئيسية (ويب)
// ============================================
function include(filename) {
  return HtmlService.createHtmlOutputFromFile(filename).getContent();
}

function doGet(e) {
  return HtmlService.createTemplateFromFile('index')
    .evaluate()
    .setTitle('الأماني - نظام عروض الأسعار الرسمية')
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
}

// ============================================
// API الموبايل (Flutter) — doPost
// ============================================
function doPost(e) {
  try {
    const body   = JSON.parse(e.postData.contents);
    const action = body.action;
    let result;

    switch (action) {
      case 'saveQuotation':
        result = saveQuotation(body.data);
        break;
      case 'getAllProducts':
        result = { success: true, data: getAllProducts() };
        break;
      case 'addProduct':
        result = addProduct(body.data);
        break;
      case 'deleteProduct':
        result = deleteProduct(body.name);
        break;
      case 'getNextQuotationNumber':
        result = { success: true, number: getNextQuotationNumber() };
        break;
      default:
        result = { success: false, message: 'إجراء غير معروف: ' + action };
    }

    return ContentService
      .createTextOutput(JSON.stringify(result))
      .setMimeType(ContentService.MimeType.JSON);
  } catch (error) {
    return ContentService
      .createTextOutput(JSON.stringify({ success: false, message: error.toString() }))
      .setMimeType(ContentService.MimeType.JSON);
  }
}

// ============================================
// حفظ عرض السعر في Google Sheets
// ============================================
function saveQuotation(data) {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    let sheet = ss.getSheetByName(SHEET_NAME);

    if (!sheet) {
      sheet = ss.insertSheet(SHEET_NAME);
      const headers = [
        'رقم العرض', 'التاريخ', 'اسم الزبون', 'الهاتف', 'العنوان',
        'المشروع', 'المنتج', 'الوحدة', 'العدد', 'السعر',
        'الإجمالي', 'الاجمالي الكلي', 'نسبة الخصم', 'قيمة الخصم', 'الصافي',
        'الملاحظات', 'مدة التنفيذ', 'حالة'
      ];
      sheet.getRange(1, 1, 1, headers.length).setValues([headers])
        .setFontWeight('bold').setBackground('#1a237e')
        .setFontColor('#ffffff').setHorizontalAlignment('center');
    }

    const quotationNumber = generateQuotationNumber(sheet);
    const dateStr = Utilities.formatDate(new Date(), 'Asia/Baghdad', 'yyyy-MM-dd HH:mm');
    const rows = [];

    data.items.forEach(item => {
      rows.push([
        quotationNumber,              dateStr,
        data.customerName,            data.customerPhone    || '',
        data.customerAddress  || '',  data.projectName      || '',
        item.productName,             item.unit             || 'قطعة',
        parseFloat(item.qty),         parseFloat(item.price),
        parseFloat(item.total),       parseFloat(data.grandTotal),
        parseFloat(data.discountPercent) || 0,
        parseFloat(data.discountValue)   || 0,
        parseFloat(data.netTotal),
        data.notes || '', data.duration || '', 'جديد'
      ]);
    });

    if (rows.length > 0) {
      sheet.getRange(sheet.getLastRow() + 1, 1, rows.length, rows[0].length).setValues(rows);
    }

    return { success: true, quotationNumber, message: 'تم حفظ عرض السعر — رقم العرض: ' + quotationNumber };
  } catch (error) {
    return { success: false, message: 'خطأ في الحفظ: ' + error.toString() };
  }
}

// ============================================
// توليد رقم العرض — إصلاح: يفحص كل الصفوف + سنة ديناميكية
// ============================================
function generateQuotationNumber(sheet) {
  const year   = new Date().getFullYear();
  const prefix = 'AM-' + year + '-';

  if (sheet.getLastRow() <= 1) return prefix + '0001';

  const values = sheet.getRange(2, 1, sheet.getLastRow() - 1, 1).getValues().flat();
  let maxNum = 0;

  values.forEach(v => {
    if (v && typeof v === 'string' && v.startsWith(prefix)) {
      const n = parseInt(v.slice(prefix.length), 10);
      if (!isNaN(n) && n > maxNum) maxNum = n;
    }
  });

  return prefix + (maxNum + 1).toString().padStart(4, '0');
}

function getNextQuotationNumber() {
  try {
    const ss    = SpreadsheetApp.getActiveSpreadsheet();
    const sheet = ss.getSheetByName(SHEET_NAME);
    if (!sheet || sheet.getLastRow() <= 1)
      return 'AM-' + new Date().getFullYear() + '-0001';
    return generateQuotationNumber(sheet);
  } catch (e) {
    return 'AM-' + new Date().getFullYear() + '-0001';
  }
}

// ============================================
// إدارة قاعدة بيانات المنتجات
// ============================================
function getOrCreateImagesFolder() {
  const folders = DriveApp.getFoldersByName(IMAGES_FOLDER_NAME);
  return folders.hasNext() ? folders.next() : DriveApp.createFolder(IMAGES_FOLDER_NAME);
}

function setupProductsSheet() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName(PRODUCTS_SHEET_NAME);
  if (!sheet) {
    sheet = ss.insertSheet(PRODUCTS_SHEET_NAME);
    const h = ['اسم المنتج', 'الوحدة', 'السعر الافتراضي', 'معرف الصورة (Drive)', 'الصورة (base64)'];
    sheet.getRange(1, 1, 1, 5).setValues([h])
      .setFontWeight('bold').setBackground('#1a237e').setFontColor('#fff');
    sheet.setFrozenRows(1);
    [160, 80, 130, 200, 50].forEach((w, i) => sheet.setColumnWidth(i + 1, w));
  }
  return sheet;
}

function getAllProducts() {
  try {
    const ss    = SpreadsheetApp.getActiveSpreadsheet();
    const sheet = ss.getSheetByName(PRODUCTS_SHEET_NAME);
    if (!sheet || sheet.getLastRow() <= 1) return [];
    return sheet.getRange(2, 1, sheet.getLastRow() - 1, 5).getValues()
      .filter(r => r[0])
      .map(r => ({
        name        : String(r[0]).trim(),
        unit        : r[1] ? String(r[1]).trim() : 'قطعة',
        price       : parseFloat(r[2]) || 0,
        imageBase64 : r[4] ? String(r[4]) : ''
      }));
  } catch (e) { return []; }
}

function addProduct(pd) {
  try {
    const sheet = setupProductsSheet();

    if (sheet.getLastRow() > 1) {
      const names = sheet.getRange(2, 1, sheet.getLastRow() - 1, 1).getValues().flat().map(String);
      if (names.includes(pd.name))
        return { success: false, message: 'هذا المنتج موجود مسبقاً في القائمة' };
    }

    // إصلاح: حد أقصى 40,000 حرف لتجنب تجاوز حد خلية Sheets (50,000)
    let imageBase64 = pd.imageBase64 || '';
    if (imageBase64.length > 40000) imageBase64 = '';

    let fileId = '';
    if (pd.imageBase64 && pd.imageBase64.includes('base64,')) {
      try {
        const folder   = getOrCreateImagesFolder();
        const parts    = pd.imageBase64.split(';base64,');
        const mimeType = parts[0].replace('data:', '');
        const ext      = mimeType.includes('png') ? 'png' : 'jpg';
        const blob     = Utilities.newBlob(Utilities.base64Decode(parts[1]), mimeType, pd.name + '.' + ext);
        const file     = folder.createFile(blob);
        file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
        fileId = file.getId();
      } catch (imgErr) { console.log('Drive upload skipped: ' + imgErr); }
    }

    sheet.getRange(sheet.getLastRow() + 1, 1, 1, 5)
         .setValues([[pd.name, pd.unit || 'قطعة', parseFloat(pd.price) || 0, fileId, imageBase64]]);

    return { success: true, message: 'تم إضافة المنتج بنجاح' };
  } catch (e) {
    return { success: false, message: 'خطأ في الإضافة: ' + e.message };
  }
}

function deleteProduct(name) {
  try {
    const ss    = SpreadsheetApp.getActiveSpreadsheet();
    const sheet = ss.getSheetByName(PRODUCTS_SHEET_NAME);
    if (!sheet || sheet.getLastRow() <= 1)
      return { success: false, message: 'المنتج غير موجود' };

    const data = sheet.getRange(2, 1, sheet.getLastRow() - 1, 5).getValues();
    for (let i = 0; i < data.length; i++) {
      if (String(data[i][0]) === name) {
        if (data[i][3]) {
          try { DriveApp.getFileById(data[i][3]).setTrashed(true); } catch (e) {}
        }
        sheet.deleteRow(i + 2);
        return { success: true, message: 'تم حذف المنتج بنجاح' };
      }
    }
    return { success: false, message: 'المنتج غير موجود' };
  } catch (e) {
    return { success: false, message: 'خطأ في الحذف: ' + e.message };
  }
}
