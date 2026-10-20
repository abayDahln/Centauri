// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'Centauri — แคนวาส UI/UX ด้วย AI';

  @override
  String get languageTooltip => 'ภาษา';

  @override
  String get languageDialogTitle => 'ภาษา';

  @override
  String get commonAdd => 'เพิ่ม';

  @override
  String get commonRetry => 'ลองอีกครั้ง';

  @override
  String get commonEdit => 'แก้ไข';

  @override
  String get commonDelete => 'ลบ';

  @override
  String get commonCancel => 'ยกเลิก';

  @override
  String get commonSave => 'บันทึก';

  @override
  String get commonClose => 'ปิด';

  @override
  String get commonActive => 'ใช้งานอยู่';

  @override
  String get commonSetActive => 'ตั้งเป็นใช้งาน';

  @override
  String get commonProvider => 'Provider';

  @override
  String get commonBaseUrl => 'Base URL';

  @override
  String get commonApiKey => 'API Key';

  @override
  String get commonModel => 'Model';

  @override
  String get providerListHeading => 'Bring Your Own Key (BYOK)';

  @override
  String get providerListSubtitle =>
      'ข้อมูลทั้งหมดถูกเก็บและเข้ารหัสไว้ในเครื่องของคุณ';

  @override
  String get providerListLoadFailed => 'โหลด Provider ไม่ได้';

  @override
  String get providerListEmptyTitle => 'ยังไม่มี Provider';

  @override
  String get providerListEmptyBody => 'เพิ่ม Provider เพื่อเริ่มใช้ Centauri';

  @override
  String get providerListAddProvider => 'เพิ่ม Provider';

  @override
  String get providerDeleted => 'ลบ Provider แล้ว';

  @override
  String get providerDetailPickProvider => 'เลือก Provider ก่อน';

  @override
  String get providerDetailPickModel => 'เลือก Model ก่อน';

  @override
  String providerDetailSaveFailed(String error) {
    return 'บันทึกไม่ได้: $error';
  }

  @override
  String providerDetailClearKeyFailed(String error) {
    return 'ลบ API Key ไม่ได้: $error';
  }

  @override
  String get providerDetailUpdated => 'อัปเดต Provider แล้ว';

  @override
  String get providerDetailAdded => 'เพิ่ม Provider แล้ว';

  @override
  String get providerDetailTestOk => 'เชื่อมต่อได้';

  @override
  String get providerDetailTitleEdit => 'แก้ไข Provider';

  @override
  String get providerDetailTitleNew => 'เพิ่ม Provider';

  @override
  String get providerDetailDeleteTooltip => 'ลบ Provider';

  @override
  String get providerDetailFieldName => 'ชื่อ';

  @override
  String get providerDetailNameHint => 'เช่น \"OpenAI Pro\"';

  @override
  String get providerDetailNameRequired => 'ต้องใส่ชื่อ';

  @override
  String get providerDetailPickProviderLabel => 'เลือก Provider';

  @override
  String get providerDetailFieldProviderName => 'ชื่อ Provider';

  @override
  String get providerDetailProviderNameHint => 'เช่น \"OpenAI\"';

  @override
  String get providerDetailProviderNameRequired => 'ต้องใส่ชื่อ Provider';

  @override
  String get providerDetailPickModelLabel => 'เลือก Model';

  @override
  String get providerDetailPickProviderFirst => 'เลือก Provider ก่อน';

  @override
  String get providerDetailTestAction => 'ทดสอบ';

  @override
  String get providerDetailBaseUrlRequired => 'ต้องใส่ Base URL';

  @override
  String get providerDetailBaseUrlInvalid =>
      'ใส่ URL ที่ถูกต้อง (ตัวอย่าง: https://...)';

  @override
  String get providerDetailApiKeyFromProvider => 'จาก Provider';

  @override
  String get providerDetailApiKeyStored =>
      'บันทึก API Key แล้ว กดรีเซ็ตเพื่อเปลี่ยน';

  @override
  String get providerDetailApiKeyCleared => 'API Key จะถูกลบเมื่อบันทึก';

  @override
  String get providerDetailApiKeyOptional =>
      'เว้นว่างไว้สำหรับบริการในเครื่องที่ไม่ต้องยืนยันตัวตน';

  @override
  String get providerDetailReset => 'รีเซ็ต';

  @override
  String get providerDeleteTargetFallback => 'Provider นี้';

  @override
  String get providerDeleteTitle => 'ลบ Provider นี้?';

  @override
  String providerDeleteBody(String target) {
    return '$target และข้อมูลที่บันทึกไว้จะถูกลบถาวร';
  }

  @override
  String get modelCardDeleteTooltip => 'ลบ Model';

  @override
  String get modelCardCopyIdTooltip => 'คัดลอก ID ของ Model';

  @override
  String modelCardCopied(String model) {
    return 'คัดลอกแล้ว: $model';
  }

  @override
  String get modelPickerTitle => 'เลือก Model';

  @override
  String get modelPickerCustom => 'Model กำหนดเอง';

  @override
  String get modelPickerAddModel => 'เพิ่ม Model';

  @override
  String get modelPickerIdHint => 'เช่น \"gpt-4o\"';

  @override
  String get providerPickerTitle => 'เลือก Provider';

  @override
  String get commonAllPages => 'ทุกหน้า';

  @override
  String get canvasUntitledProject => 'ต้นแบบใหม่';

  @override
  String get canvasHideHistory => 'ซ่อนประวัติ';

  @override
  String get canvasShowHistory => 'แสดงประวัติ';

  @override
  String get canvasHideChat => 'ซ่อนแชต';

  @override
  String get canvasShowChat => 'แสดงแชต';

  @override
  String get canvasHidePreview => 'ซ่อนตัวอย่าง';

  @override
  String get canvasShowPreview => 'แสดงตัวอย่าง';

  @override
  String get canvasUndoTooltip => 'เลิกทำ (Ctrl+Z)';

  @override
  String get canvasRedoTooltip => 'ทำซ้ำ (Ctrl+Y)';

  @override
  String canvasPageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count หน้า',
    );
    return '$_temp0';
  }

  @override
  String get canvasModeDesign => 'ออกแบบ';

  @override
  String get canvasModeCode => 'โค้ด';

  @override
  String get canvasShowCode => 'แสดงโค้ด';

  @override
  String get canvasHideCode => 'ซ่อนโค้ด';

  @override
  String get canvasServiceSettings => 'ตั้งค่าบริการ';

  @override
  String get canvasSelectionOff => 'หยุดเลือกองค์ประกอบ';

  @override
  String get canvasSelectionOn => 'เลือกองค์ประกอบบนแคนวาส';

  @override
  String get canvasBreadcrumbFallback => 'แคนวาส';

  @override
  String get canvasStopGenerating => 'หยุดสร้าง';

  @override
  String get canvasStopAction => 'หยุด';

  @override
  String get canvasEmptyTitle => 'ยังไม่มี UI';

  @override
  String get canvasEmptyBody => 'พิมพ์ข้อความเพื่อเริ่ม';

  @override
  String get canvasPrototypeTitle => 'ต้นแบบ';

  @override
  String get canvasChatPanelTooltip => 'แผงแชตและประวัติ';

  @override
  String get storageFailedTitle => 'เปิดที่เก็บข้อมูลในเครื่องไม่ได้ ';

  @override
  String get storageFailedBody => 'ปิดหน้าต่าง Centauri อีกอันแล้วลองอีกครั้ง';

  @override
  String get previewGenericError => 'เกิดข้อผิดพลาดในตัวอย่าง';

  @override
  String previewLinkInvalid(String href) {
    return 'ลิงก์ไม่ถูกต้อง: $href';
  }

  @override
  String previewLinkOpenFailed(String href) {
    return 'เปิดไม่ได้: $href';
  }

  @override
  String previewPageNotFound(String href) {
    return 'ไม่พบหน้า: $href';
  }

  @override
  String get previewDeleteFailed => 'ลบองค์ประกอบไม่ได้ ลองอีกครั้ง';

  @override
  String get previewLoading => 'กำลังโหลด…';

  @override
  String get previewNoPagesTitle => 'ยังไม่มีหน้า';

  @override
  String get previewNoPagesBody => 'พิมพ์ข้อความเพื่อสร้างหน้า';

  @override
  String get previewLoadFailedTitle => 'โหลดตัวอย่างไม่ได้';

  @override
  String get previewWebView2Hint =>
      'ถ้ายังไม่หาย ให้ติดตั้ง Microsoft Edge WebView2 Runtime';

  @override
  String get exportNoPages => 'ยังไม่มีหน้าที่จะส่งออก';

  @override
  String exportSaved(String path) {
    return 'บันทึกแล้ว: $path';
  }

  @override
  String exportFigmaCopied(int count) {
    return 'คัดลอกข้อมูล Figma แล้ว ($count องค์ประกอบ)';
  }

  @override
  String exportFigmaSaved(int count, String path) {
    return 'บันทึกข้อมูล Figma แล้ว ($count องค์ประกอบ): $path';
  }

  @override
  String get exportFailed => 'ส่งออกไม่ได้ ลองอีกครั้ง';

  @override
  String get exportPageTooltip => 'ส่งออกหน้า';

  @override
  String get exportPageTooltipCompact => 'ส่งออกหน้า (PNG/SVG/PDF/Figma)';

  @override
  String get exportPng => 'PNG (รูปภาพ)';

  @override
  String get exportSvg => 'SVG (เวกเตอร์)';

  @override
  String get exportPdf => 'PDF (เอกสาร)';

  @override
  String get exportAction => 'ส่งออก';

  @override
  String get codePanelCopied => 'คัดลอก HTML แล้ว';

  @override
  String get codePanelCopyTooltip => 'คัดลอก HTML';

  @override
  String get codePanelSaveTooltip => 'บันทึกเป็น .html';

  @override
  String get codePanelEmpty => 'ยังไม่มีโค้ด\nสร้าง UI ก่อน';

  @override
  String get promptAnalyzeImage => 'วิเคราะห์รูปนี้';

  @override
  String promptUnsupportedFormat(String name) {
    return 'ไม่รองรับรูปแบบ \"$name\"';
  }

  @override
  String promptReadFailed(String name) {
    return 'อ่าน \"$name\" ไม่ได้';
  }

  @override
  String get promptPlaceholder => 'พิมพ์ข้อความ…';

  @override
  String get promptAttachTooltip => 'แนบไฟล์';

  @override
  String get promptStopTooltip => 'หยุดสร้าง';

  @override
  String get promptMentionPagesTooltip => 'อ้างถึงหน้า';

  @override
  String get attachmentImageFailed => 'แสดงรูปไม่ได้';

  @override
  String get attachmentRemoveTooltip => 'ลบไฟล์แนบ';

  @override
  String get chatWelcomeTitle => 'เริ่มด้วยข้อความ';

  @override
  String get chatWelcomeBody => 'ถามคำแนะนำการออกแบบ หรือให้สร้างให้เลย';

  @override
  String get chatTabChat => 'แชต';

  @override
  String get chatTabHistory => 'ประวัติ';

  @override
  String get pageRenameTitle => 'เปลี่ยนชื่อหน้า';

  @override
  String get pageRenameHint => 'ชื่อหน้า';

  @override
  String pageSlugTooltip(String slug) {
    return '$slug\n(ดับเบิลคลิกเพื่อเปลี่ยนชื่อ)';
  }

  @override
  String get markdownEmpty => '(ว่าง)';

  @override
  String get windowMinimize => 'ย่อ';

  @override
  String get windowMaximize => 'ขยาย';

  @override
  String get windowRestore => 'คืนค่า';

  @override
  String get windowClose => 'ปิด';

  @override
  String get historyRenameTitle => 'เปลี่ยนชื่อ';

  @override
  String get historyRenameHint => 'ชื่อแชต';

  @override
  String get historyNewChat => 'แชตใหม่';

  @override
  String get historySearchHint => 'ค้นหาแชต';

  @override
  String get historyRecent => 'ล่าสุด';

  @override
  String get historyRenameTooltip => 'เปลี่ยนชื่อ';

  @override
  String get historyEmptySearch => 'ไม่พบแชตที่ตรงกัน';

  @override
  String get historyEmptyList => 'ยังไม่มีแชตที่บันทึกไว้';

  @override
  String get codeExportTitle => 'ส่งออกโค้ด';

  @override
  String codeExportCopied(String format) {
    return 'คัดลอกโค้ด $format แล้ว';
  }

  @override
  String codeExportCharCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ตัวอักษร',
    );
    return '$_temp0';
  }

  @override
  String get codeExportCopy => 'คัดลอก';

  @override
  String get codeExportDownload => 'ดาวน์โหลด';

  @override
  String get codeExportNoticeHtml =>
      'ไฟล์ HTML เดียวที่ครบในตัว: รวม CSS และ JS ใช้ได้แบบออฟไลน์';

  @override
  String get codeExportNoticeReact =>
      'เป็นการแปลงโดยประมาณ ย้ายเนื้อหาใน <style> ไปไฟล์ CSS แล้วตรวจสอบก่อนใช้';

  @override
  String get codeExportNoticeFlutter =>
      'เป็นการแปลงโดยประมาณ แปลงเฉพาะสไตล์แบบอินไลน์ ไม่รวม CSS ใน <style> ตรวจสอบก่อนใช้';

  @override
  String get codeExportNoticeTailwind =>
      'เป็นการแปลงโดยประมาณ ต้องใช้ Tailwind v3.2+ ย้ายเนื้อหาใน <style> ไปไฟล์ CSS ตรวจสอบก่อนใช้';

  @override
  String get codeExportTransformErrorTitle => 'แปลงโค้ดไม่ได้';

  @override
  String codeExportTransformErrorFallback(String format) {
    return 'แปลงโค้ดของ Alpha เป็น $format ไม่ได้';
  }

  @override
  String get codeExportUseHtml => 'ใช้ HTML';

  @override
  String get codeExportEmptyTitle => 'ยังไม่มี UI ให้ส่งออก';

  @override
  String get codeExportEmptyBody => 'สร้าง UI ก่อน';

  @override
  String get mcpDesktopTitle => 'MCP Server (Desktop)';

  @override
  String get mcpDesktopOnlyDesc => 'MCP ทำงานเฉพาะบน Desktop';

  @override
  String get mcpRunning => 'กำลังทำงาน';

  @override
  String get mcpStopped => 'หยุดแล้ว';

  @override
  String get mcpDescription =>
      'สะพานให้ AI agent (Claude Code, Cursor) ดูและแก้ไขดีไซน์แบบสด';

  @override
  String get mcpStarting => 'กำลังเริ่ม…';

  @override
  String get mcpStart => 'เริ่ม';

  @override
  String get mcpAutoStartNote => 'เซิร์ฟเวอร์เริ่มอัตโนมัติเมื่อเปิดแอป';

  @override
  String get mcpCopyAddress => 'คัดลอก';

  @override
  String get mcpAddressCopied => 'คัดลอกที่อยู่แล้ว';

  @override
  String mcpToolsList(String tools) {
    return 'Tools: $tools';
  }

  @override
  String get chatProcessing => 'กำลังประมวลผล…';

  @override
  String get chatUiReady => 'UI พร้อม';

  @override
  String get chatViewCode => 'ดูโค้ด';

  @override
  String get chatHideCode => 'ซ่อน';

  @override
  String get chatNoMessagesTitle => 'ยังไม่มีบทสนทนา';

  @override
  String get chatNoMessagesBody => 'พิมพ์ข้อความเพื่อเริ่ม';

  @override
  String get commonGenericError => 'เกิดข้อผิดพลาด ลองอีกครั้ง';

  @override
  String get canvasMentionElementFallback => 'องค์ประกอบที่เลือก';

  @override
  String get canvasNoProvider => 'ยังไม่มี Provider ที่ใช้งาน เพิ่มก่อนเริ่ม';

  @override
  String get canvasUntitledPage => 'ไม่มีชื่อ';

  @override
  String get canvasGenerationStopped => 'หยุดการสร้างแล้ว';

  @override
  String get promptAttachmentLimit => 'แนบได้สูงสุด 6 ไฟล์ต่อข้อความ';

  @override
  String get providerNotFound => 'ไม่พบ Provider';

  @override
  String get errorCancelled => 'ยกเลิกแล้ว';

  @override
  String get errorApiTimeout =>
      'การเชื่อมต่อหมดเวลา ตรวจสอบที่อยู่หรือเครือข่าย';

  @override
  String get errorApiUnreachable => 'เชื่อมต่อไม่ได้ ตรวจสอบที่อยู่';

  @override
  String get errorApiUnauthorized => 'คีย์การเข้าถึงไม่ถูกต้องหรือไม่มีสิทธิ์';

  @override
  String get errorApiRateLimited =>
      'บริการกำลังจำกัดคำขอ ลองอีกครั้งในอีกสักครู่';

  @override
  String get errorApiNotFound => 'ไม่พบที่อยู่หรือ Model ตรวจสอบทั้งสองอย่าง';

  @override
  String get errorApiRejected => 'บริการปฏิเสธคำขอ';

  @override
  String get errorApiCertificate =>
      'ใบรับรองเซิร์ฟเวอร์ไม่ถูกต้อง ตรวจสอบที่อยู่';

  @override
  String get errorApiSendFailed =>
      'ส่งคำขอไม่ได้ ตรวจสอบการเชื่อมต่อและที่อยู่';

  @override
  String get errorApiBadResponse =>
      'รูปแบบการตอบกลับไม่ตรงกับที่คาด ที่อยู่ควรลงท้ายด้วย /v1';

  @override
  String get errorApiNoChatEndpoint => 'บริการนี้ยังไม่มีที่อยู่สำหรับแชท';

  @override
  String get errorApiModelUnavailable =>
      'Model นี้ใช้ไม่ได้ที่นี่ เลือกอันอื่น';

  @override
  String get errorApiConnectionBroken => 'การเชื่อมต่อขาดหาย ลองอีกครั้ง';

  @override
  String errorApiProviderReported(String detail) {
    return 'ข้อความจากบริการ: $detail';
  }

  @override
  String get errorGenerationTimeout =>
      'หยุดการสร้างแล้ว ใช้เวลานานเกินไป ลองอีกครั้ง';

  @override
  String get errorExportNotReady => 'หน้านี้ยังไม่พร้อม รอสักครู่';

  @override
  String get errorExportTimeout => 'การส่งออกหมดเวลา ลองอีกครั้ง';

  @override
  String get errorExportNoElements => 'ยังไม่มีอะไรให้ส่งออก';

  @override
  String get errorExportEmptyResult => 'ผลลัพธ์ว่างเปล่า ลองอีกครั้ง';

  @override
  String get errorExportWriteFailed => 'บันทึกไฟล์ไม่ได้ เลือกตำแหน่งอื่น';

  @override
  String get errorImportInvalidFile =>
      'ไฟล์นี้ไม่ใช่ JSON ที่ถูกต้อง เลือกไฟล์ .mydesign ของ Centauri';

  @override
  String get errorImportNotProject => 'นี่ไม่ใช่ไฟล์โปรเจกต์ของ Centauri';

  @override
  String errorImportNewerVersion(String version) {
    return 'ไฟล์นี้ต้องใช้ Centauri เวอร์ชันใหม่กว่า ($version) อัปเดตแอปก่อน';
  }

  @override
  String get errorImportEmpty => 'ไฟล์โปรเจกต์นี้ว่างเปล่า';

  @override
  String errorImportEmptyFile(String name) {
    return 'ไฟล์ $name ว่างเปล่า';
  }

  @override
  String get errorImportUnusable => 'อ่านไฟล์ไม่ได้ เลือกไฟล์อื่น';

  @override
  String errorImportUnusableFile(String name) {
    return 'อ่านไฟล์ $name ไม่ได้ เลือกไฟล์อื่น';
  }

  @override
  String get errorAttachmentEmpty => 'ไฟล์ว่างเปล่า';

  @override
  String errorAttachmentEmptyFile(String name) {
    return 'ไฟล์ $name ว่างเปล่า';
  }

  @override
  String errorAttachmentTooLarge(int maxMb) {
    return 'ไฟล์ใหญ่เกินไป (สูงสุด $maxMb MB)';
  }

  @override
  String errorAttachmentUnsupported(String formats) {
    return 'ไม่รองรับรูปแบบนี้ ใช้ $formats';
  }

  @override
  String get errorStorageFailed => 'เข้าถึงคีย์บนอุปกรณ์นี้ไม่ได้';

  @override
  String get errorTransformNoCode => 'หน้านี้ยังไม่มีโค้ด';

  @override
  String get exportFigma => 'Figma';

  @override
  String get catalogSectionFreeTier => 'แพ็กเกจฟรี';

  @override
  String get catalogSectionApiKey => 'API Key';

  @override
  String get appearanceTooltip => 'รูปลักษณ์';

  @override
  String get appearanceTitle => 'รูปลักษณ์';

  @override
  String get appearanceModeLabel => 'โหมด';

  @override
  String get appearanceModeSystem => 'ระบบ';

  @override
  String get appearanceModeLight => 'สว่าง';

  @override
  String get appearanceModeDark => 'มืด';

  @override
  String get appearancePrimaryLabel => 'สีหลัก';

  @override
  String get appearanceReset => 'รีเซ็ต';

  @override
  String get commonDone => 'เสร็จสิ้น';

  @override
  String get colorBlue => 'น้ำเงิน';

  @override
  String get colorIndigo => 'อินดิโก';

  @override
  String get colorViolet => 'ม่วง';

  @override
  String get colorTeal => 'ทีล';

  @override
  String get colorGreen => 'เขียว';

  @override
  String get colorAmber => 'แอมเบอร์';

  @override
  String get colorRose => 'ชมพู';

  @override
  String get colorSlate => 'เทาอมฟ้า';
}
