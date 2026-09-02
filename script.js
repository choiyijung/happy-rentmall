document.querySelectorAll(".segmented").forEach(group => {
  const hidden = group.parentElement.querySelector('input[type="hidden"]');

  group.querySelectorAll("button").forEach(button => {
    button.addEventListener("click", () => {
      group.querySelectorAll("button").forEach(b => b.classList.remove("active"));
      button.classList.add("active");

      if (hidden) {
        hidden.value = button.dataset.value || button.textContent.trim();
      }
    });
  });
});

const form = document.getElementById("quoteForm");

form?.addEventListener("submit", async (e) => {
  e.preventDefault();

  const data = new FormData(form);

  if (!data.get("car") || !data.get("name") || !data.get("phone")) {
    alert("희망 차량, 고객명, 휴대폰번호를 입력해주세요.");
    return;
  }

  if (!data.get("privacy_agree")) {
    alert("개인정보 수집 및 이용 동의가 필요합니다.");
    return;
  }

  const submitButton = form.querySelector('[type="submit"]');
  const originalText = submitButton?.textContent;

  if (submitButton) {
    submitButton.disabled = true;
    submitButton.textContent = "접수 중...";
  }

  const isCarPage = window.location.pathname.includes("/cars/");

  const region =
    isCarPage
      ? ""
      : (document.querySelector("h1")?.textContent.trim() || "");

  const payload = {
    name: data.get("name"),
    phone: data.get("phone"),
    car: data.get("car"),
    consultation_type: data.get("type") || "",
    months: data.get("months") || "",
    region,
    page_url: window.location.href,
    privacy_agreed: true
  };

  try {
    const response = await fetch(
      "/.netlify/functions/submit-consultation",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify(payload)
      }
    );

    const result = await response.json();

    if (!response.ok || !result.ok) {
      throw new Error(result.message || "상담 접수에 실패했습니다.");
    }

    alert("상담 신청이 정상적으로 접수되었습니다.");

    form.querySelector('[name="name"]').value = "";
    form.querySelector('[name="phone"]').value = "";

    const privacy = form.querySelector('[name="privacy_agree"]');
    if (privacy) privacy.checked = false;

  } catch (error) {
    alert(error.message || "상담 접수 중 오류가 발생했습니다.");
  } finally {
    if (submitButton) {
      submitButton.disabled = false;
      submitButton.textContent = originalText;
    }
  }
});

document.getElementById("callPlaceholder")?.addEventListener("click", () => {
  alert("대표 전화번호가 정해지면 전화 연결 버튼으로 변경합니다.");
});
