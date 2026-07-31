// Wrapper around the centralized EmailService located in src/services.
// Keeps existing call signature: sendEmail({ email, subject, message })
const EmailService = require('../src/services/email.service');
const logger = require('./logger');

/**
 * Send an email using the centralized EmailService.
 * @param {{email: string, subject: string, message: string}} options
 */
async function sendEmail(options) {
  const to = options.email;
  const subject = options.subject || '';
  const message = options.message || '';

  try {
    // Use the HTML-friendly sendMail helper. Wrap plain text in a simple paragraph.
    const html = `<p>${String(message)}</p>`;
    const info = await EmailService.sendMail(to, subject, html);
    logger.info('utils.sendEmail: sent to %s messageId=%s', to, info.messageId);
    return info;
  } catch (err) {
    logger.error('utils.sendEmail failed for %s: %s', to, err.message || err);
    // Re-throw so callers can handle and return appropriate responses.
    throw err;
  }
}

module.exports = sendEmail;
