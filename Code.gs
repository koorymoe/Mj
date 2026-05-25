// ============================================
// نظام عرض السعر الرسمي - شركة الأماني
// Code.gs — الملف الكامل والنهائي
// يشمل: حفظ العروض + إدارة المنتجات وصورهم
// ============================================

const SHEET_NAME          = "عروض_الاسعار";
const PRODUCTS_SHEET_NAME = "قاعدة_المنتجات";
const IMAGES_FOLDER_NAME  = "أماني_صور_المنتجات";

// ============================================
// الواجهة الرئيسية
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
// حفظ عرض السعر في Google Sheets
// ============================================
function saveQuotation(data) {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    let sheet = ss.getSheetByName(SHEET_NAME);

    if (!sheet) {
      sheet = ss.insertSheet(SHEET_NAME);
      const headers = [
        "رقم العرض","التاريخ","اسم الزبون","الهاتف","العنوان",
        "المشروع","المنتج","الوحدة","العدد","السعر",
        "الإجمالي","الاجمالي الكلي","نسبة الخصم","قيمة الخصم","الصافي",
        "الملاحظات","مدة التنفيذ","حالة"
      ];
      sheet.getRange(1,1,1,headers.length).setValues([headers])
        .setFontWeight("bold").setBackground("#1a237e")
        .setFontColor("#ffffff").setHorizontalAlignment("center");
      sheet.setColumnWidth(1,100);
      sheet.setColumnWidth(3,180);
    }

    const quotationNumber = generateQuotationNumber(sheet);
    const dateStr = Utilities.formatDate(new Date(),"Asia/Baghdad","yyyy-MM-dd HH:mm");

    const rows = [];
    data.items.forEach(item => {
      rows.push([
        quotationNumber, dateStr,
        data.customerName, data.customerPhone||"",
        data.customerAddress||"", data.projectName||"",
        item.productName, item.unit||"قطعة",
        parseFloat(item.qty), parseFloat(item.price), parseFloat(item.total),
        parseFloat(data.grandTotal), parseFloat(data.discountPercent)||0,
        parseFloat(data.discountValue)||0, parseFloat(data.netTotal),
        data.notes||"", data.duration||"", "جديد"
      ]);
    });

    if (rows.length > 0) {
      const lastRow = sheet.getLastRow();
      sheet.getRange(lastRow+1,1,rows.length,rows[0].length).setValues(rows);
    }

    return {
      success: true,
      quotationNumber,
      message: "تم حفظ عرض السعر بنجاح - رقم العرض: " + quotationNumber
    };
  } catch(error) {
    return { success:false, message:"خطأ في الحفظ: "+error.toString() };
  }
}

// ============================================
// توليد رقم عرض السعر التسلسلي
// ============================================
function generateQuotationNumber(sheet) {
  const lastRow = sheet.getLastRow();
  if (lastRow <= 1) return "AM-2026-0001";
  const lastNum = sheet.getRange(lastRow,1).getValue();
  if (!lastNum || typeof lastNum !== 'string') return "AM-2026-0001";
  const match = lastNum.match(/\d{4}$/);
  if (!match) return "AM-2026-0001";
  return "AM-2026-" + (parseInt(match[0])+1).toString().padStart(4,'0');
}

function getNextQuotationNumber() {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const sheet = ss.getSheetByName(SHEET_NAME);
    if (!sheet || sheet.getLastRow() <= 1) return "AM-2026-0001";
    return generateQuotationNumber(sheet);
  } catch(e) { return "AM-2026-0001"; }
}

// ============================================
// إدارة قاعدة بيانات المنتجات + صورهم في Drive
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
    const h = ["اسم المنتج","الوحدة","السعر الافتراضي","معرف الصورة (Drive)","الصورة (base64)"];
    sheet.getRange(1,1,1,5).setValues([h])
      .setFontWeight("bold").setBackground("#1a237e").setFontColor("#fff");
    sheet.setFrozenRows(1);
    [160,80,130,200,50].forEach((w,i) => sheet.setColumnWidth(i+1,w));
  }
  return sheet;
}

// جلب كل المنتجات — العمود E يحتوي base64 مباشرةً
function getAllProducts() {
  try {
    const ss    = SpreadsheetApp.getActiveSpreadsheet();
    const sheet = ss.getSheetByName(PRODUCTS_SHEET_NAME);
    if (!sheet || sheet.getLastRow() <= 1) return [];
    const lastCol = Math.max(sheet.getLastColumn(), 5);
    return sheet.getRange(2,1,sheet.getLastRow()-1,lastCol).getValues()
      .filter(r => r[0])
      .map(r => ({
        name        : String(r[0]).trim(),
        unit        : r[1] ? String(r[1]).trim() : 'قطعة',
        price       : parseFloat(r[2]) || 0,
        imageBase64 : r[4] ? String(r[4]) : ''   // عمود E — base64 مباشرةً
      }));
  } catch(e) { return []; }
}

// إضافة منتج — يحفظ الصورة في الشيت (عمود E) وفي Drive (عمود D) كنسخة احتياطية
function addProduct(pd) {
  try {
    const sheet = setupProductsSheet();

    // تحقق من عدم التكرار
    if (sheet.getLastRow() > 1) {
      const names = sheet.getRange(2,1,sheet.getLastRow()-1,1)
                         .getValues().flat().map(String);
      if (names.includes(pd.name))
        return { success:false, message:'هذا المنتج موجود مسبقاً في القائمة' };
    }

    // رفع الصورة إلى Drive (اختياري — نسخة احتياطية)
    let fileId = '';
    if (pd.imageBase64 && pd.imageBase64.includes('base64,')) {
      try {
        const folder   = getOrCreateImagesFolder();
        const parts    = pd.imageBase64.split(';base64,');
        const mimeType = parts[0].replace('data:','');
        const ext      = mimeType.includes('png') ? 'png' : 'jpg';
        const blob     = Utilities.newBlob(
                           Utilities.base64Decode(parts[1]),
                           mimeType,
                           pd.name + '.' + ext
                         );
        const file = folder.createFile(blob);
        file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
        fileId = file.getId();
      } catch(imgErr) {
        console.log('Drive upload skipped: ' + imgErr);
      }
    }

    // حفظ: اسم، وحدة، سعر، Drive fileId، base64 مباشرةً
    sheet.getRange(sheet.getLastRow()+1,1,1,5)
         .setValues([[pd.name, pd.unit||'قطعة', parseFloat(pd.price)||0,
                      fileId, pd.imageBase64 || '']]);

    return { success:true, message:'تم إضافة المنتج بنجاح ✓' };
  } catch(e) {
    return { success:false, message:'خطأ في الإضافة: '+e.message };
  }
}

// حذف منتج وصورته من Drive
function deleteProduct(name) {
  try {
    const ss    = SpreadsheetApp.getActiveSpreadsheet();
    const sheet = ss.getSheetByName(PRODUCTS_SHEET_NAME);
    if (!sheet || sheet.getLastRow() <= 1)
      return { success:false, message:'المنتج غير موجود' };

    const data = sheet.getRange(2,1,sheet.getLastRow()-1,5).getValues();
    for (let i=0; i<data.length; i++) {
      if (String(data[i][0]) === name) {
        // حذف الصورة من Drive إذا وجدت
        if (data[i][3]) {
          try { DriveApp.getFileById(data[i][3]).setTrashed(true); } catch(e){}
        }
        sheet.deleteRow(i+2);
        return { success:true, message:'تم حذف المنتج بنجاح' };
      }
    }
    return { success:false, message:'المنتج غير موجود' };
  } catch(e) {
    return { success:false, message:'خطأ في الحذف: '+e.message };
  }
}
