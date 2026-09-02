const { Client } = require("pg");

exports.handler = async function(event) {
  const headers = {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store"
  };

  if (event.httpMethod !== "POST") {
    return {
      statusCode: 405,
      headers,
      body: JSON.stringify({ ok: false, message: "Method Not Allowed" })
    };
  }

  let client;

  try {
    const body = JSON.parse(event.body || "{}");

    const clean = (value, maxLength) =>
      String(value ?? "").trim().slice(0, maxLength);

    const name = clean(body.name, 50);
    const phone = clean(body.phone, 30);
    const car = clean(body.car, 100);
    const consultationType = clean(body.consultation_type, 30);
    const months = clean(body.months, 30);
    const region = clean(body.region, 120);
    const pageUrl = clean(body.page_url, 500);

    if (!name || !phone || !car) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({
          ok: false,
          message: "필수 상담정보가 누락되었습니다."
        })
      };
    }

    if (body.privacy_agreed !== true) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({
          ok: false,
          message: "개인정보 수집 및 이용 동의가 필요합니다."
        })
      };
    }

    if (!/^[0-9+\-\s()]{8,30}$/.test(phone)) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({
          ok: false,
          message: "휴대폰번호를 확인해주세요."
        })
      };
    }

    const password = process.env.DB_PASSWORD;

    if (!password) {
      throw new Error("DB_PASSWORD environment variable is missing.");
    }

    client = new Client({
      host: "aws-0-ap-northeast-2.pooler.supabase.com",
      port: 6543,
      database: "postgres",
      user: "postgres.lgkbpwekslpkjvjthhxq",
      password,
      ssl: {
        rejectUnauthorized: false
      },
      connectionTimeoutMillis: 10000
    });

    await client.connect();

    await client.query(
      `
      insert into public.consultations (
        name,
        phone,
        car,
        consultation_type,
        months,
        region,
        page_url,
        privacy_agreed,
        privacy_agreed_at
      )
      values ($1,$2,$3,$4,$5,$6,$7,true,now())
      `,
      [
        name,
        phone,
        car,
        consultationType || null,
        months || null,
        region || null,
        pageUrl || null
      ]
    );

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({
        ok: true,
        message: "상담 신청이 정상적으로 접수되었습니다."
      })
    };

  } catch (error) {
    console.error("Consultation DB error:", error);

    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        ok: false,
        message: "상담 접수 중 오류가 발생했습니다."
      })
    };

  } finally {
    if (client) {
      try {
        await client.end();
      } catch {}
    }
  }
};
