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

    const supabaseUrl = process.env.SUPABASE_URL;
    const secretKey = process.env.SUPABASE_SECRET_KEY;

    if (!supabaseUrl || !secretKey) {
      throw new Error("Supabase environment variables are missing.");
    }

    const response = await fetch(
      `${supabaseUrl}/rest/v1/consultations`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "apikey": secretKey,
          "Prefer": "return=minimal"
        },
        body: JSON.stringify({
          name,
          phone,
          car,
          consultation_type: consultationType || null,
          months: months || null,
          region: region || null,
          page_url: pageUrl || null,
          privacy_agreed: true,
          privacy_agreed_at: new Date().toISOString()
        })
      }
    );

    if (!response.ok) {
      const errorText = await response.text();
      console.error("Supabase insert failed:", response.status, errorText);

      return {
        statusCode: 500,
        headers,
        body: JSON.stringify({
          ok: false,
          message: "상담 접수 중 오류가 발생했습니다."
        })
      };
    }

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({
        ok: true,
        message: "상담 신청이 정상적으로 접수되었습니다."
      })
    };

  } catch (error) {
    console.error("Consultation function error:", error);

    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        ok: false,
        message: "상담 접수 중 오류가 발생했습니다."
      })
    };
  }
};