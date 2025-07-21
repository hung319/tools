// js/rdname.js
document.addEventListener("DOMContentLoaded", function() {
    var hoNam = ["Nguyễn", "Trần", "Lê", "Phạm", "Hoàng", "Huỳnh", "Võ", "Đặng", "Bùi", "Đỗ", "Hồ", "Ngô", "Dương", "Lý", "Đào", "Đoàn", "Vương", "Trịnh", "Đinh", "Lưu"];
    var hoNu = ["Nguyễn Thị", "Trần Thị", "Lê Thị", "Phạm Thị", "Hoàng Thị", "Võ Thị", "Đặng Thị", "Bùi Thị", "Đỗ Thị", "Hồ Thị", "Ngô Thị", "Dương Thị"];
    var tenNam = ["Văn", "Hữu", "Đức", "Hải", "Dương", "Minh", "Quang", "Khang", "Tuấn", "Anh", "Bảo", "Duy", "Phúc", "Long", "Việt"];
    var tenNu = ["Thị", "Hồng", "Mai", "Thu", "Hạnh", "Phương", "Linh", "Như", "Tâm", "Giang", "Trang", "Thảo", "Hà", "Yến", "Nga"];
    var tenDemNam = ["Minh", "Quang", "Ngọc", "Đức", "Hữu", "Văn", "Hoàng", "Bảo", "Gia", "Thiên"];
    var tenDemNu = ["Ngọc", "Thu", "Bảo", "Mai", "Vân", "Thị", "Phương", "Thùy", "Mỹ", "Khánh"];

    var tenList = document.getElementById("tenList");
    var gioiTinhSelect = document.getElementById("gioiTinh");
    var soLuongInput = document.getElementById("soLuong");
    var generateButton = document.getElementById("generateButton");

    function generateNames() {
        var gioiTinh = gioiTinhSelect.value;
        var hoList = gioiTinh === "nam" ? hoNam : hoNu;
        var tenListArr = gioiTinh === "nam" ? tenNam : tenNu;
        var tenDemList = gioiTinh === "nam" ? tenDemNam : tenDemNu;
        var soLuong = parseInt(soLuongInput.value);

        tenList.innerHTML = "";
        for (var i = 0; i < soLuong; i++) {
            var hoNgauNhien = hoList[Math.floor(Math.random() * hoList.length)];
            var tenDemNgauNhien = tenDemList[Math.floor(Math.random() * tenDemList.length)];
            var tenNgauNhien = tenListArr[Math.floor(Math.random() * tenListArr.length)];
            var tenDayDu = `${hoNgauNhien} ${tenDemNgauNhien} ${tenNgauNhien}`;
            
            var listItem = document.createElement("li");
            listItem.textContent = tenDayDu;
            listItem.classList.add("copyable");
            tenList.appendChild(listItem);
        }
    }

    generateNames();

    generateButton.addEventListener("click", generateNames);

    tenList.addEventListener("click", function(event) {
        if (event.target.tagName === "LI") {
            var textToCopy = event.target.textContent;
            navigator.clipboard.writeText(textToCopy).then(function() {
                // Thay đổi tạm thời nội dung để báo đã copy
                const originalText = event.target.textContent;
                event.target.textContent = "Đã sao chép!";
                setTimeout(() => {
                    event.target.textContent = originalText;
                }, 1000);
            }, function(err) {
                console.error('Lỗi khi sao chép: ', err);
            });
        }
    });

    // Vẫn giữ logic chặn chuột phải theo code gốc
    document.addEventListener("contextmenu", function(event) {
        event.preventDefault();
    });
});