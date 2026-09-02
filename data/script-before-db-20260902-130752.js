document.querySelectorAll(".segmented").forEach(group => {
  const hidden = group.parentElement.querySelector('input[type="hidden"]');
  group.querySelectorAll("button").forEach(button => {
    button.addEventListener("click", () => {
      group.querySelectorAll("button").forEach(b => b.classList.remove("active"));
      button.classList.add("active");
      if (hidden) hidden.value = button.dataset.value || button.textContent.trim();
    });
  });
});

const form = document.getElementById("quoteForm");
form?.addEventListener("submit", (e) => {
  e.preventDefault();
  const data = new FormData(form);
  if (!data.get("car") || !data.get("name") || !data.get("phone")) {
    alert("희망 차량, 고객명, 휴대폰번호를 입력해주세요.");
    return;
  }
  if (!data.get("privacy")) {
    alert("개인정보 수집 및 이용 동의가 필요합니다.");
    return;
  }
  alert("현재는 화면용 샘플입니다.\n실제 접수 방식이 정해지면 이 버튼에 전송 기능을 연결할 수 있습니다.");
});

document.getElementById("callPlaceholder")?.addEventListener("click", () => {
  alert("대표 전화번호가 정해지면 전화 연결 버튼으로 변경합니다.");
});
