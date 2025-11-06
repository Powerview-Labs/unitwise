/**
 * EMAIL CLIENT - TEST MODE
 * This version doesn't crash if SendGrid credentials are missing
 */

function maskEmail(email) {
  if (!email || !email.includes('@')) {
    return '***INVALID***';
  }
  const [local, domain] = email.split('@');
  if (local.length <= 2) {
    return `${local[0]}***@${domain}`;
  }
  const maskedLocal = `${local[0]}${'*'.repeat(local.length - 2)}${local[local.length - 1]}`;
  return `${maskedLocal}@${domain}`;
}

async function sendWelcomeEmail(toEmail, userName) {
  const maskedEmail = maskEmail(toEmail);
  
  console.log(`[SendGrid] TEST MODE - Would send welcome email to ${maskedEmail}`);
  console.log(`[SendGrid] TEST MODE - User: ${userName}`);
  
  return {
    success: true,
    messageId: `MSG_TEST_${Date.now()}`,
  };
}

async function sendPasswordResetEmail(toEmail, userName, otp) {
  const maskedEmail = maskEmail(toEmail);
  
  console.log(`[SendGrid] TEST MODE - Would send password reset email to ${maskedEmail}`);
  console.log(`[SendGrid] TEST MODE - OTP: ${otp}`);
  
  return {
    success: true,
    messageId: `MSG_TEST_${Date.now()}`,
  };
}

const EMAIL_TEMPLATES = {
  welcome: {
    subject: 'Welcome to UnitWise',
  },
};

module.exports = {
  sendWelcomeEmail,
  sendPasswordResetEmail,
  maskEmail,
  EMAIL_TEMPLATES,
};
