/**
 * EcoRoute Arua — Official Rider Invitation Mail Gateway
 * Deployed as Web App via Google Apps Script (ecoroute.waste@gmail.com)
 *
 * Spam-Proof Deliverability Architecture:
 * 1. Uses GmailApp.sendEmail for direct authenticated Google mailbox transmission with valid SPF, DKIM, and DMARC.
 * 2. Synchronized Dual Multipart Body (Plain Text + Clean Accessible HTML) to avoid spam penalties.
 * 3. Invisible preheader snippet prevents raw links/CSS from showing in inbox preview list.
 * 4. CAN-SPAM & GDPR compliant physical municipal operations footer with verified reply-to address.
 * 5. High text-to-code ratio without hype words, all-caps, or deceptive tracking elements.
 */

function doPost(e) {
  try {
    const data = JSON.parse(e.postData.contents);
    const riderEmail = (data.email || '').trim().toLowerCase();
    const riderName = (data.name || 'Rider').trim();
    const inviteLink = data.inviteLink || 'https://coder-cliff.github.io/ecoRoute/';
    const inviteCode = data.inviteCode || 'RIDER-' + Math.floor(100000 + Math.random() * 900000);
    const tricycleId = data.tricycleId || 'TRIC-04 (Ediofe Depot)';
    const senderName = 'EcoRoute Fleet Operations (Arua City Council)';
    const subject = 'EcoRoute Arua: Official Rider Authorization & Tricycle Assignment';

    // 1. Synchronized Plain-Text Body for Spam-Filter Compliance
    const plainTextBody = 
`Hello ${riderName},

Welcome to the EcoRoute municipal solid waste collection team for Arua City.

An official rider dispatch account has been authorized for you by Arua City Council Fleet Operations.

Your Authorization Details:
- Driver Name: ${riderName}
- Assigned Tricycle: ${tricycleId}
- Authorization Token: ${inviteCode}
- Operations Hotline: +256 394 880 352

To activate your account and start your collection route, open your live portal:
${inviteLink}

Collection Operations Protocol:
1. Ensure your tricycle cargo bay is securely fastened before starting your shift.
2. Verify waste sack counts and collect the 4-digit confirmation PIN from residents.
3. Transport segregated materials to designated municipal transfer hubs for weighing.

If you received this operational authorization in error, please disregard this email or contact Arua dispatch.

EcoRoute Municipal Solid Waste Operations
Arua City Council Logistics & Muni University Campus
Plot 4 Avenue Road, Central Division, Arua City, West Nile, Uganda
Official Dispatch: ecoroute.waste@gmail.com`;

    // 2. High-Deliverability, Table-Based HTML Body
    const htmlBody = `
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${subject}</title>
</head>
<body style="margin: 0; padding: 0; background-color: #eef2ed; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #1a3a28;">

  <!-- Preheader text for clean email preview snippet -->
  <div style="display: none; font-size: 1px; color: #ffffff; line-height: 1px; max-height: 0px; max-width: 0px; opacity: 0; overflow: hidden; mso-hide: all;">
    Official municipal collection driver authorization and dispatch credentials for Arua City.
  </div>

  <table border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: #eef2ed; padding: 24px 12px;">
    <tr>
      <td align="center">
        <table border="0" cellpadding="0" cellspacing="0" width="100%" style="max-width: 560px; background-color: #ffffff; border-radius: 20px; border: 1px solid #d8e2d7; box-shadow: 0 4px 12px rgba(13, 38, 24, 0.05); overflow: hidden;">
          
          <!-- Header Banner -->
          <tr>
            <td style="background-color: #0d2618; padding: 24px 28px; text-align: left;">
              <table border="0" cellpadding="0" cellspacing="0" width="100%">
                <tr>
                  <td>
                    <span style="display: inline-block; font-size: 22px; font-weight: 800; color: #ffffff; letter-spacing: -0.5px;">EcoRoute</span>
                    <span style="display: block; font-size: 11px; font-weight: 600; color: #a3cfb1; text-transform: uppercase; letter-spacing: 1px; margin-top: 3px;">Arua City Council • Municipal Waste Logistics</span>
                  </td>
                  <td align="right">
                    <span style="background-color: #1a3a28; color: #d8e8dc; font-size: 11px; font-weight: 700; padding: 6px 12px; border-radius: 999px; border: 1px solid #2d553c;">Official Notice</span>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Main Content -->
          <tr>
            <td style="padding: 28px;">
              <h2 style="color: #0d2618; margin: 0 0 12px 0; font-size: 19px; font-weight: 700;">
                Collection Rider Authorization
              </h2>
              <p style="color: #334438; font-size: 14px; line-height: 1.6; margin: 0 0 20px 0;">
                Hello <strong>${riderName}</strong>,<br>
                Your rider dispatch account has been officially authorized by Arua Municipal Fleet Headquarters for tricycle waste collection service across Ayivu, Central Division, and Muni University sectors.
              </p>

              <!-- Operational Credentials Card -->
              <table border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: #f5f8f5; border: 1px solid #dce6db; border-radius: 14px; margin-bottom: 24px; padding: 16px;">
                <tr>
                  <td>
                    <table border="0" cellpadding="6" cellspacing="0" width="100%" style="font-size: 13px;">
                      <tr>
                        <td style="color: #617366; width: 38%; font-weight: 600;">Authorized Driver:</td>
                        <td style="color: #0d2618; font-weight: 700;">${riderName}</td>
                      </tr>
                      <tr>
                        <td style="color: #617366; font-weight: 600;">Assigned Tricycle:</td>
                        <td style="color: #0d2618; font-weight: 700;">${tricycleId}</td>
                      </tr>
                      <tr>
                        <td style="color: #617366; font-weight: 600;">Authorization Token:</td>
                        <td style="font-family: monospace; font-size: 14px; font-weight: 800; color: #9c3d18;">${inviteCode}</td>
                      </tr>
                      <tr>
                        <td style="color: #617366; font-weight: 600;">Dispatch Hotline:</td>
                        <td style="color: #0d2618; font-weight: 700;">+256 394 880 352</td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>

              <!-- Call to Action Button -->
              <table border="0" cellpadding="0" cellspacing="0" width="100%" style="margin-bottom: 24px;">
                <tr>
                  <td align="center">
                    <a href="${inviteLink}" target="_blank" style="background-color: #0d2618; color: #ffffff; display: inline-block; padding: 14px 32px; font-size: 14px; font-weight: 700; text-decoration: none; border-radius: 12px; box-shadow: 0 3px 6px rgba(13, 38, 24, 0.2);">
                      Activate Dispatch Terminal &rarr;
                    </a>
                  </td>
                </tr>
              </table>

              <p style="color: #5d6e62; font-size: 12px; line-height: 1.5; margin: 0 0 16px 0; text-align: center;">
                Direct URL: <a href="${inviteLink}" style="color: #0d2618; word-break: break-all;">${inviteLink}</a>
              </p>

              <!-- Municipal Protocol -->
              <div style="border-top: 1px solid #e5ede4; padding-top: 16px; margin-top: 16px;">
                <span style="font-size: 11px; font-weight: 700; color: #0d2618; text-transform: uppercase; letter-spacing: 0.5px; display: block; margin-bottom: 8px;">Collection Shift Reminders:</span>
                <ul style="font-size: 12px; color: #495a4f; margin: 0; padding-left: 20px; line-height: 1.6;">
                  <li>Verify sack count and segregation category prior to loading.</li>
                  <li>Collect the 4-digit verification code from the resident to settle the trip.</li>
                  <li>Deliver loaded tricycles to municipal weighing stations.</li>
                </ul>
              </div>

            </td>
          </tr>

          <!-- Footer Compliance Block (CAN-SPAM / GDPR) -->
          <tr>
            <td style="background-color: #f9fbf9; border-top: 1px solid #e5ede4; padding: 20px 28px; text-align: center; font-size: 11px; color: #728477; line-height: 1.5;">
              <p style="margin: 0 0 6px 0;">
                <strong>EcoRoute Municipal Solid Waste Operations</strong><br>
                Arua City Council Logistics &amp; Muni University Campus<br>
                Plot 4 Avenue Road, Central Division, Arua, West Nile, Uganda
              </p>
              <p style="margin: 0; font-size: 10px; color: #8e9e92;">
                This official administrative communication was sent to <span style="color: #0d2618;">${riderEmail}</span>. If you were invited in error, please disregard this notice or contact dispatch at <a href="mailto:ecoroute.waste@gmail.com" style="color: #0d2618;">ecoroute.waste@gmail.com</a>.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>

</body>
</html>
`;

    // Dispatch via GmailApp (Ensures valid SPF, DKIM, and DMARC alignment)
    GmailApp.sendEmail(riderEmail, subject, plainTextBody, {
      htmlBody: htmlBody,
      name: senderName,
      replyTo: 'ecoroute.waste@gmail.com'
    });

    return ContentService
      .createTextOutput(JSON.stringify({ status: 'sent', recipient: riderEmail, code: inviteCode }))
      .setMimeType(ContentService.MimeType.JSON);

  } catch (err) {
    return ContentService
      .createTextOutput(JSON.stringify({ status: 'error', message: err.toString() }))
      .setMimeType(ContentService.MimeType.JSON);
  }
}
