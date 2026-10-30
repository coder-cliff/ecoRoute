/**
 * EcoRoute Arua — Official Rider Invitation Mail Gateway
 * Deployed as Web App via Google Apps Script (ecoroute.waste@gmail.com)
 *
 * Deliverability Optimizations:
 * 1. Uses GmailApp.sendEmail (direct Gmail mailbox transmission with valid SPF/DKIM).
 * 2. Provides synchronized plain-text body + HTML body (prevents spam filter penalty).
 * 3. Specifies sender name and replyTo address.
 * 4. High-reputation subject line without spam-triggering characters.
 */

function doPost(e) {
  try {
    const data = JSON.parse(e.postData.contents);
    const riderEmail = data.email;
    const riderName = data.name || 'Rider';
    const inviteLink = data.inviteLink || 'https://coder-cliff.github.io/ecoRoute/';
    const senderName = data.senderName || 'EcoRoute Municipal Operations';
    const subject = data.subject || 'EcoRoute Collection Team Onboarding: Arua Operations';

    const plainTextBody = 
`Hello ${riderName},

Welcome to the EcoRoute collection team for Arua City.

Your rider dispatch account has been authorized for the municipal tricycle waste collection fleet serving Ayivu, Central Division, and Muni University.

Your live dispatch portal is ready at:
${inviteLink}

Collection operations reminder:
1. Ensure your tricycle cargo bay is securely fastened before transit.
2. Confirm sack counts and waste categories at resident pickup locations.
3. Transport loaded sacks to designated municipal sorting hubs for scale weighing.

If you have questions, contact municipal dispatch or reply directly to this email.

EcoRoute Municipal Waste Operations
Muni University & Arua City Council Logistics
Arua, West Nile, Uganda
ecoroute.waste@gmail.com`;

    const htmlBody = `
      <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; max-width: 540px; margin: 0 auto; padding: 28px; border: 1px solid #d6e8d8; border-radius: 16px; background-color: #ffffff;">
        <div style="text-align: center; margin-bottom: 24px;">
          <h1 style="color: #0d2618; margin: 0; font-size: 24px; font-weight: 700; letter-spacing: -0.3px;">EcoRoute</h1>
          <p style="color: #1a3a28; font-size: 13.5px; margin: 4px 0 0 0;">Sustainable Waste Logistics • Arua City</p>
        </div>

        <h2 style="color: #0d2618; margin-top: 0; font-size: 18px; font-weight: 700;">Welcome to EcoRoute Fleet, ${riderName}!</h2>
        <p style="color: #2b3a30; line-height: 1.6; font-size: 14.5px;">
          Your rider account has been authorized for the municipal tricycle waste collection fleet serving Ayivu, Central Division, and Muni University.
        </p>
        <p style="color: #2b3a30; line-height: 1.6; font-size: 14.5px;">
          Click the button below to complete your rider registration and open your live collection dispatch board:
        </p>

        <div style="text-align: center; margin: 28px 0;">
          <a href="${inviteLink}" style="background-color: #0d2618; color: #72b08d; padding: 14px 32px; text-decoration: none; border-radius: 12px; font-weight: 700; font-size: 15px; display: inline-block;">
            Open Rider Portal
          </a>
        </div>

        <p style="font-size: 12px; color: #556958; line-height: 1.5;">
          Direct link: <a href="${inviteLink}" style="color: #0d2618; word-break: break-all;">${inviteLink}</a>
        </p>

        <hr style="border: none; border-top: 1px solid #e2eae1; margin: 24px 0;" />

        <p style="font-size: 11.5px; color: #71877d; margin: 0; text-align: center; line-height: 1.5;">
          Sent by EcoRoute Municipal Operations • ecoroute.waste@gmail.com<br>
          Arua City Council & Muni University Logistics • Arua, Uganda
        </p>
      </div>
    `;

    // Use GmailApp for direct authenticated mailbox transmission (better deliverability)
    GmailApp.sendEmail(riderEmail, subject, plainTextBody, {
      htmlBody: htmlBody,
      name: senderName,
      replyTo: 'ecoroute.waste@gmail.com'
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
