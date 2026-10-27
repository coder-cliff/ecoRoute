/**
 * EcoRoute Arua — Official Rider Invitation Mail Gateway
 * Deployed as Web App via Google Apps Script (ecoroute.waste@gmail.com)
 * Uses Google Apps Script MailApp API:
 * https://developers.google.com/apps-script/reference/mail/mail-app
 */

function doPost(e) {
  try {
    const data = JSON.parse(e.postData.contents);
    const riderEmail = data.email;
    const riderName = data.name || 'Rider';
    const inviteLink = data.inviteLink || 'https://coder-cliff.github.io/ecoRoute/';

    MailApp.sendEmail({
      to: riderEmail,
      subject: 'EcoRoute Arua — Official Rider Invitation',
      htmlBody: `
        <div style="font-family: Arial, sans-serif; max-width: 520px; padding: 24px; border: 1px solid #d6e8d8; border-radius: 14px; background-color: #ffffff;">
          <div style="text-align: center; margin-bottom: 20px;">
            <h1 style="color: #1b5e20; margin: 0; font-size: 24px;">EcoRoute Arua</h1>
            <p style="color: #2e7d32; font-size: 13px; margin: 4px 0 0 0;">Municipal Waste & Recycling Logistics</p>
          </div>

          <h2 style="color: #1b5e20; margin-top: 0; font-size: 18px;">Welcome to EcoRoute, ${riderName}!</h2>
          <p style="color: #333333; line-height: 1.5; font-size: 14px;">
            You have been officially invited to join the <strong>EcoRoute Waste Logistics</strong> team as an authorized collection rider serving Arua City.
          </p>
          <p style="color: #333333; line-height: 1.5; font-size: 14px;">
            Click the button below to accept your invitation, verify your credentials, and access your live rider dispatch board:
          </p>

          <div style="text-align: center; margin: 28px 0;">
            <a href="${inviteLink}" style="background-color: #2e7d32; color: #ffffff; padding: 14px 28px; text-decoration: none; border-radius: 10px; font-weight: bold; font-size: 15px; display: inline-block;">
              Accept Rider Invitation
            </a>
          </div>

          <p style="font-size: 12px; color: #666666; line-height: 1.4;">
            If the button doesn't work, copy and paste this link into your browser:<br>
            <a href="${inviteLink}" style="color: #2e7d32;">${inviteLink}</a>
          </p>

          <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 24px 0;" />

          <p style="font-size: 11px; color: #888888; margin: 0; text-align: center;">
            Sent officially by EcoRoute Waste Management • ecoroute.waste@gmail.com<br>
            Arua City, West Nile, Uganda
          </p>
        </div>
      `
    });

    return ContentService
      .createTextOutput(JSON.stringify({ status: 'sent', recipient: riderEmail }))
      .setMimeType(ContentService.MimeType.JSON);
  } catch (err) {
    return ContentService
      .createTextOutput(JSON.stringify({ status: 'error', message: err.toString() }))
      .setMimeType(ContentService.MimeType.JSON);
  }
}
