import { SESClient, SendTemplatedEmailCommand } from '@aws-sdk/client-ses';
import type { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';

const ses = new SESClient({ region: process.env['SES_REGION'] ?? 'us-east-1' });

const HEADERS = {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*',
};

interface ContactBody {
  name: string;
  email: string;
  message: string;
}

const validateBody = (body: unknown): body is ContactBody => {
  if (typeof body !== 'object' || body === null) return false;
  const { name, email, message } = body as Record<string, unknown>;
  return (
    typeof name === 'string' && name.trim().length > 0 &&
    typeof email === 'string' && email.trim().length > 0 &&
    typeof message === 'string' && message.trim().length > 0
  );
};

export const main = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  try {
    const body: unknown = JSON.parse(event.body ?? '{}');

    if (!validateBody(body)) {
      return {
        statusCode: 400,
        headers: HEADERS,
        body: JSON.stringify({
          message: 'Missing or invalid fields: name, email and message are required',
        }),
      };
    }

    const { name, email, message } = body;
    const fromEmail = process.env['FROM_EMAIL'] ?? '';
    const ownerEmail = process.env['OWNER_EMAIL'] ?? '';
    const notificationTemplate = process.env['NOTIFICATION_TEMPLATE'] ?? '';
    const confirmationTemplate = process.env['CONFIRMATION_TEMPLATE'] ?? '';
    const templateData = JSON.stringify({ name, email, message });

    await Promise.all([
      ses.send(new SendTemplatedEmailCommand({
        Source: fromEmail,
        ReplyToAddresses: [ownerEmail],
        Destination: { ToAddresses: [ownerEmail] },
        Template: notificationTemplate,
        TemplateData: templateData,
      })),
      ses.send(new SendTemplatedEmailCommand({
        Source: fromEmail,
        ReplyToAddresses: [ownerEmail],
        Destination: { ToAddresses: [email] },
        Template: confirmationTemplate,
        TemplateData: templateData,
      })),
    ]);

    return {
      statusCode: 200,
      headers: HEADERS,
      body: JSON.stringify({ message: 'Email sent successfully' }),
    };
  } catch (error) {
    console.error('Error:', error);

    return {
      statusCode: 500,
      headers: HEADERS,
      body: JSON.stringify({
        message: 'Error sending email',
        error: error instanceof Error ? error.message : 'Unknown error',
      }),
    };
  }
};
