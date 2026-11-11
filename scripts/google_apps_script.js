/**
 * EcoRoute Arua - Google Apps Script Email Relay (scripts.google.com)
 * 
 * Instructions to deploy on scripts.google.com:
 * 1. Open https://script.google.com
 * 2. Create a new project named "EcoRoute Email Relay"
 * 3. Replace all code in Code.gs with this script
 * 4. Click "Deploy" -> "New deployment"
 * 5. Select type: "Web app"
 * 6. Set Description: "EcoRoute Email Relay v1"
 * 7. Execute as: "Me (your google account e.g. ecoroute.waste@gmail.com)"
 * 8. Who has access: "Anyone" (allows the mobile app and GitHub Pages web app to POST without auth tokens)
 * 9. Click "Deploy" and authorize permissions.
 * 10. Copy the Web App URL (starts with https://script.google.com/macros/s/...)
 */

function doPost(e) {
  try {
    if (!e || !e.postData || !e.postData.contents) {
      return ContentService.createTextOutput(JSON.stringify({
        status: "error",
        message: "No post data received"
      })).setMimeType(ContentService.MimeType.JSON);
    }

    var payload = JSON.parse(e.postData.contents);
    var recipient = payload.email || payload.toEmail;
    var subject = payload.subject || "EcoRoute Notification";
    var body = payload.body || "Notification from EcoRoute Operations";
    var htmlBody = payload.htmlBody || null;
    var senderName = payload.senderName || "EcoRoute Operations (Arua City Council)";

    if (!recipient) {
      return ContentService.createTextOutput(JSON.stringify({
        status: "error",
        message: "Missing recipient email address"
      })).setMimeType(ContentService.MimeType.JSON);
    }

    var mailOptions = {
      to: recipient,
      subject: subject,
      body: body,
      name: senderName
    };

    if (htmlBody) {
      mailOptions.htmlBody = htmlBody;
    }

    MailApp.sendEmail(mailOptions);

    return ContentService.createTextOutput(JSON.stringify({
      status: "success",
      recipient: recipient,
      timestamp: new Date().toISOString()
    })).setMimeType(ContentService.MimeType.JSON);

  } catch (err) {
    return ContentService.createTextOutput(JSON.stringify({
      status: "error",
      message: err.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  }
}

function doGet(e) {
  return ContentService.createTextOutput(JSON.stringify({
    service: "EcoRoute Google Apps Script Email Relay",
    status: "online",
    activeTime: new Date().toISOString()
  })).setMimeType(ContentService.MimeType.JSON);
}
