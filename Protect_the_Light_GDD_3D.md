# Game Design Document: Protect the Light

*Co-op Survival Horror-lite / Stealth-lite — 3D Góc nhìn thứ ba — Low-poly — Permadeath — 30 phút — Godot 4.7*

---

## 1. Tổng quan

| Thông tin | Chi tiết |
|-----------|----------|
| **Tên** | Protect the Light |
| **Thể loại** | Co-op Survival Horror-lite / Stealth-lite |
| **Số người chơi** | 2–4 người (Online bắt buộc) |
| **Thời lượng** | ~30 phút cho một lần chơi thành công |
| **Góc nhìn** | 3D góc thứ ba (over-the-shoulder), camera bám sau nhân vật |
| **Phong cách hình ảnh** | Low-poly stylized — ưu tiên ánh sáng/bóng đổ hơn chi tiết hình học |
| **Engine** | Godot 4.7 (3D pipeline) |
| **Cơ chế chết** | Permadeath — chết là chơi lại từ đầu toàn bộ game |
| **Độ khó** | Cao — biên độ sai sót thấp, đòi hỏi phối hợp gần như liên tục |

**Triết lý thiết kế:** Một nhóm 2–4 người chỉ có duy nhất một nguồn sáng để sống sót trong không gian 3D thật — nơi bóng tối không còn là một vùng vẽ trên mặt phẳng mà là những góc khuất, hành lang hẹp, và khối hình thật sự có thể che khuất tầm nhìn. Việc chuyển sang 3D không thay đổi triết lý cốt lõi (không dựa vào phản xạ nhanh, mà dựa vào giao tiếp và quản lý rủi ro), nhưng khuếch đại cảm giác đe dọa nhờ ánh sáng động và không gian chiều sâu thật.

**Vì sao chọn 3D thay vì top-down 2D:** Cơ chế lõi của game — ánh sáng, bóng tối, tầm nhìn, cảm giác bị bao vây — vốn dĩ là những yếu tố không gian ba chiều thể hiện tốt hơn nhiều so với top-down. Bóng đổ dài, vật cản che khuất thật, và cảm giác đứng trong một hành lang hẹp tối om đều là những trải nghiệm chỉ 3D mới tạo ra được trọn vẹn.

**Đánh đổi cần chấp nhận:** Khối lượng sản xuất asset (model, animation, rigging), độ phức tạp networking, và yêu cầu kỹ năng team tăng đáng kể so với bản 2D. Phong cách low-poly được chọn có chủ đích để giảm gánh nặng này — xem mục 15.

---

## 2. Core Fantasy & Cảm xúc mục tiêu

- Cảm giác đứng giữa bóng tối thật, nơi vùng sáng quanh đuốc là ranh giới sống còn có thể nhìn thấy và cảm nhận chiều sâu
- Phụ thuộc lẫn nhau cao — một sai lầm có thể khiến cả đội mất trắng
- Áp lực leo thang gần như liên tục, chỉ có đúng một điểm nghỉ trong toàn game
- Nỗi sợ mất mát là động lực chính: gần 30 phút công sức có thể tan biến trong vài giây bất cẩn
- Khoảnh khắc giải tỏa mạnh khi Torch Bearer bước vào vòng sáng cuối cùng, quan sát được toàn bộ khung cảnh 3D mở ra

---

## 3. Góc nhìn & Camera

- **Góc thứ ba, camera bám sau nhân vật (over-the-shoulder)**, khoảng cách camera-nhân vật: 3.5–4.5m, có thể zoom nhẹ khi vào không gian hẹp
- Lý do chọn thứ ba thay vì thứ nhất: cơ chế co-op cần nhìn thấy đồng đội, biết ai đang cầm đuốc, quan sát trạng thái nhóm — góc thứ nhất sẽ làm mất khả năng này trừ khi thêm UI phức tạp bù đắp
- Camera tự động điều chỉnh khoảng cách/góc khi vào hành lang hẹp (Khu 4) để tránh clipping vào tường
- Khi độ bền đuốc thấp (<20%), thêm hiệu ứng rung camera nhẹ + vignette tối ở rìa màn hình để tăng cảm giác nguy hiểm

---

## 4. Vai trò

### Torch Bearer (Người cầm đuốc) — chỉ 1 người tại một thời điểm
- Tốc độ: **2.7 m/s** (giảm 15–20% so với base)
- Máu: 80 HP
- Không có sát thương thật — chỉ đẩy lùi (knockback) quái ở cự ly gần bằng animation đẩy đuốc
- Có thể truyền đuốc cho đồng đội: giữ nút tương tác 1.2 giây trong bán kính 1.5m, có animation trao tay rõ ràng (quan trọng trong 3D vì người chơi cần thấy hành động thật, không chỉ icon UI); bị gián đoạn nếu nhả nút, ra khỏi bán kính, hoặc một trong hai người bị tấn công trong lúc truyền

### Guardian (Người bảo vệ) — những người còn lại
- Tốc độ: **3.3 m/s** (base)
- Máu: 100 HP
- Sát thương cận chiến: 15–25 dmg/đòn tùy vũ khí, có animation vung vũ khí theo hướng camera
- Có thể nhận đuốc và dùng vật phẩm hỗ trợ

*(Ghi chú quy đổi: base speed 220 px/s ở bản 2D ≈ 3.3 m/s ở bản 3D theo tỷ lệ 1m ≈ 66px, dùng làm chuẩn quy đổi toàn bộ các khoảng cách trong tài liệu này.)*

---

## 5. Hệ thống Ánh sáng (thiết kế lại hoàn toàn cho 3D)

Trong bản 2D, ánh sáng là 3 vòng tròn đồng tâm vẽ trên mặt phẳng. Trong 3D, ánh sáng phải là **vùng thể tích thật (light volume)** với shadow casting từ địa hình và vật thể.

### Thiết lập kỹ thuật
- Đuốc dùng **OmniLight3D** (ánh sáng tỏa tròn, phù hợp với việc mọi hướng đều cần được chiếu sáng khi di chuyển)
- Bán kính và cường độ ánh sáng (energy) co giãn theo độ bền đuốc, dùng cùng công thức tỷ lệ như bản 2D nhưng quy đổi sang mét:

```
BánKínhAnToàn (m)   = 1.8 * (ĐộBền / ĐộBềnTốiĐa)
BánKínhNguyHiểm (m) = 3.3 * (ĐộBền / ĐộBềnTốiĐa)
```

- Bật **shadow casting** cho toàn bộ địa hình và vật cản lớn — đây là điểm khác biệt cốt lõi so với bản 2D: quái vật có thể thực sự ẩn sau một khối đá, một bức tường, tạo ra bóng đổ động thay đổi liên tục theo vị trí đuốc

### 3 vùng ánh sáng (giữ nguyên tinh thần, thiết kế lại cách phát hiện)

| Vùng | Bán kính (đuốc full độ bền) | Cách phát hiện trong 3D | Hiệu ứng lên người chơi | Hiệu ứng lên quái |
|------|-------------------------------|---------------------------|---------------------------|----------------------|
| An toàn | 0–1.8m | Area3D hình cầu quanh nguồn sáng, kiểm tra raycast không bị chặn | Không sát thương, hồi +1 HP/3s | Không dám vào, bị đẩy lùi nếu chạm biên |
| Nguy hiểm | 1.8–3.3m | Area3D hình cầu lớn hơn, cùng raycast | 2 dmg/2s nếu đứng >5s | Do dự, tấn công thăm dò, tốc độ -20% |
| Tối hoàn toàn | >3.3m hoặc bị vật cản chặn raycast dù ở gần | Không nhận đủ ánh sáng theo raycast (bị che khuất tính là "tối" dù gần nguồn sáng) | 8 dmg/2s | Hung hãn tối đa, tốc độ +30%, tầm nhìn +50% |

**Điểm khác biệt quan trọng so với bản 2D:** Trong 3D, một người chơi đứng sau một khối đá dù chỉ cách đuốc 2m vẫn có thể bị tính là "Tối hoàn toàn" nếu raycast từ nguồn sáng đến người chơi bị vật cản chặn. Điều này tạo ra chiều sâu chiến thuật mới hoàn toàn không có ở bản 2D — người chơi phải chú ý đến *đường thẳng tới nguồn sáng*, không chỉ khoảng cách.

---

## 6. Độ bền đuốc — Công thức (giữ nguyên giá trị số, chỉ thay đổi bối cảnh 3D)

- Độ bền tối đa: **100 điểm**
- Hao tự nhiên theo thời gian: **-0.35 điểm/giây**
- Bị Light Eater tấn công: **-10 điểm/đòn**
- Bị quái thường tấn công Torch Bearer: **-2 điểm/đòn**
- Đứng yên >3 giây trong vùng gió mạnh (Khu 3 trở đi): **-1.2 điểm/giây**, thể hiện bằng particle lá bay + animation ngọn lửa lung lay mạnh trên model đuốc 3D
- Nhặt Nhiên liệu đuốc (vật phẩm 3D dạng lọ dầu/nhánh cây, 4–5 cái/khu, không có ở Khu 4): **+25 điểm**
- Tại Rest Point duy nhất trong game: hồi đầy 100 điểm, có animation châm lại lửa

**Thể hiện hình ảnh (mới, không có ở bản 2D):** Model ngọn lửa trên đuốc co lại theo % độ bền thực tế (particle system scale theo giá trị), không chỉ là thanh UI — người chơi có thể đọc tình trạng đuốc bằng mắt thường mà không cần nhìn UI, tăng tính nhập vai.

**Ngưỡng cảnh báo:**
- Độ bền < 30: ngọn lửa 3D nhấp nháy, âm thanh cảnh báo
- Độ bền < 10: rung camera, toàn bộ quái trong bán kính lớn biết ngay vị trí nhóm (buff "săn mồi")
- Độ bền = 0: đuốc tắt, model chuyển thành khói → **Game Over ngay lập tức**

---

## 7. Cơ chế chết & Permadeath

- **Torch Bearer chết** → Game Over ngay
- **Đuốc tắt hoàn toàn** → Game Over ngay
- **Tất cả Guardian chết** → đếm ngược **10–12 giây**, quái bao vây Torch Bearer (thể hiện bằng việc quái vật 3D vây quanh thành vòng tròn nhìn thấy được); sống sót hết thời gian hoặc hạ hết quái bao vây → được cứu, hết giờ → Game Over
- **Không có checkpoint.** Chỉ có 1 Rest Point trong toàn game

---

## 8. Thiết kế Map — 4 Khu vực + Boss Area (thiết kế lại theo không gian 3D thật)

```
[Khu 1: Rừng Sương — 4 phút]
	  ↓
[Rest Point duy nhất]
	  ↓
[Khu 2: Đầm Lầy — 6 phút]
	  ↓
[Khu 3: Rừng Già & Gió Mạnh — 8 phút]
	  ↓
[Khu 4: Thành Cổ & Con Đường Cuối — 8 phút]
	  ↓
[Boss Area / Đích đến — 1–2 phút]
```

**Lưu ý quan trọng khi chuyển từ 2D sang 3D:** Layout top-down cũ (vẽ trên mặt phẳng) không thể dùng lại trực tiếp — cần thiết kế lại theo chiều đứng thật, với độ cao địa hình, độ rộng hành lang tính bằng mét, và bố trí vật cản 3D tạo góc khuất mà bản 2D không có. Mô tả dưới đây là bản thiết kế lại, giữ nguyên tinh thần/nhịp độ nhưng thích ứng không gian 3D.

### Khu 1 – Rừng Sương (4 phút)
**Layout 3D:** Đường mòn hình chữ S ngắn, hai bên là cây thấp low-poly tạo cảm giác không gian mà không cản tầm nhìn quá nhiều (phù hợp giai đoạn dạy cơ chế, cần camera thoáng).
**Sự kiện:**
1. Phút 0–1: dạy đọc thanh độ bền đuốc + quan sát ngọn lửa 3D, gặp ngay 2 Shadow Creeper cùng lúc từ hai hướng khác nhau (tận dụng không gian 3D để dạy "quan sát xung quanh" thay vì chỉ nhìn thẳng)
2. Phút 1–2.5: cầu gỗ hẹp bắc qua khe núi nhỏ (độ cao tạo cảm giác nguy hiểm rơi xuống, dù không gây damage) — bắt buộc truyền đuốc, animation trao tay rõ trên cầu hẹp
3. Phút 2.5–4: khoảng trống nhỏ có 3 điểm nhiên liệu đặt ở các độ cao khác nhau (một trên gò đất nhỏ) — tận dụng chiều đứng 3D để tạo lựa chọn không gian
4. Cuối khu: vào Rest Point — không gian mở rộng, ánh sáng ấm hơn để tạo cảm giác an toàn rõ rệt qua thị giác

### Khu 2 – Đầm Lầy (6 phút)
**Layout 3D:** Địa hình gò đất nổi cao thấp không đều, vùng nước sâu có độ trong suốt thấp (không nhìn thấy đáy — tăng cảm giác đe dọa từ Damp Lurker).
**Sự kiện:**
1. Địa hình bùn: tốc độ toàn đội -25%, thể hiện bằng animation lội bùn chậm và âm thanh đặc trưng
2. 4 điểm phục kích Damp Lurker quanh vùng nước — trong 3D, gợn sóng cảnh báo là hiệu ứng mặt nước thật (shader), chỉ 1 giây trước khi trồi lên với animation lao ra từ dưới nước
3. Một nhóm Pack Runner tuần tra trên đoạn đường vòng — quái 3D di chuyển theo formation nhìn thấy rõ, tạo cảm giác đe dọa hình khối hơn 2D
4. 4–5 điểm nhiên liệu đặt sát rìa nước
5. Sương mù thể tích (volumetric fog) giảm tầm nhìn xa — hiệu ứng chỉ khả thi đầy đủ trong 3D, thay thế cho "giảm tầm nhìn vì sương" vốn chỉ mô phỏng bằng alpha overlay ở bản 2D

### Khu 3 – Rừng Già & Gió Mạnh (8 phút)
**Layout 3D:** Nửa đầu rừng mở với cây cao tạo bóng đổ động theo gió (particle + animation cây lắc), nửa sau chuyển sang hành lang đá hẹp tối hoàn toàn (không có nguồn sáng môi trường nào ngoài đuốc).
**Sự kiện:**
1. Phút 0–3: gió mạnh thể hiện bằng particle lá bay dày đặc + âm thanh gió lớn, hao đuốc -1.2 điểm/s nếu đứng yên >3s, ngọn lửa 3D lung lay mạnh theo hướng gió
2. Phút 3–5: 2 nhóm Pack Runner tuần tra, tận dụng không gian 3D để phục kích từ phía sau cây (che khuất bằng model thật, không phải chỉ ẩn/hiện như sprite)
3. Phút 5–6.5: hành lang đá tối hoàn toàn — Torch Bearer bắt buộc đi đầu, camera thu hẹp trường nhìn tự nhiên do không gian hẹp, 2 Light Eater xuất hiện cùng lúc, lao vào đuốc với animation bay nhắm thẳng nguồn sáng (rất rõ ràng và đe dọa trong 3D)
4. Phút 6.5–8: đợt "chạy trốn" — cụm 7–8 quái xuất hiện từ nhiều hướng 3D khác nhau (không chỉ từ một phía như 2D dễ làm), buộc chạy nhanh, không có mốc định hướng rõ ràng ngoài cảm nhận không gian thật

### Khu 4 – Thành Cổ & Con Đường Cuối (8 phút)
**Layout 3D:** Mê cung hành lang đá với trần thấp tạo cảm giác ngột ngạt, chuyển sang con đường thẳng ngoài trời dẫn tới Boss Area (đối lập không gian hẹp/mở tạo nhịp điệu thị giác).
**Sự kiện:**
1. Phút 0–3: 2 cánh cửa đá cần giữ nút cơ cấu — animation cửa mở nặng nề, người giữ nút đứng tại cơ cấu 3D thật (dễ bị quái tấn công từ các hướng khác nhau vì không gian mở 3D, không chỉ từ 1-2 hướng như top-down)
2. Phút 1–3: Shadow Creeper "Dập Tắt" xuất hiện — áp sát Torch Bearer >3 giây gây thêm -7 độ bền/giây, thể hiện bằng hiệu ứng hút ánh sáng quanh model quái (particle hút ngược vào quái)
3. Phút 3–8: wave quái liên tục, spawn từ các hành lang phụ và bóng tối phía sau — tận dụng chiều sâu 3D để tạo bất ngờ thực sự (quái xuất hiện sau lưng dễ hơn nhiều so với top-down luôn nhìn thấy toàn cảnh)
4. Phút 6–8: đợt quái hỗn hợp cao trào trên con đường thẳng cuối, không có điểm nhiên liệu nào trong toàn khu
5. Đây vẫn là khu thể hiện độ khó cao nhất: 22 phút liên tục không nghỉ từ Khu 2 đến hết Khu 4

### Boss Area / Đích đến (1–2 phút)
Không gian tròn mở, vòng tròn ánh sáng Đích là một cấu trúc 3D lớn nhìn thấy từ xa ngay khi bước vào khu (tạo động lực thị giác mạnh hơn nhiều so với chỉ báo % ở bản 2D). Đợt quái dồn dập bao vây từ mọi hướng 3D khi đội tiến vào — đội phải hộ tống Torch Bearer chọc thủng vòng vây trong 60–90 giây.

---

## 9. Hệ thống Quái vật (chỉ số giữ nguyên, thiết kế lại hành vi AI cho không gian 3D)

Chỉ số từng loại quái giữ cố định như bản 2D — độ khó vẫn đến từ **mật độ và tần suất xuất hiện**, không phải làm quái mạnh hơn từng con.

| Tên quái | HP | Tốc độ | Sát thương/đòn | Hành vi AI (3D) | Cách đối phó |
|----------|----|--------|------------------|--------------------|--------------|
| Shadow Creeper | 25 | 3.0 m/s | 8 | Dùng NavMesh 3D để đuổi theo mục tiêu qua địa hình phức tạp khi ở Vùng Nguy hiểm/Tối, có thể tận dụng góc khuất để tiếp cận bất ngờ | Đánh bật hoặc kéo vào Vùng An toàn |
| Damp Lurker | 35 | 2.7 m/s (lao ra 5.3 m/s trong 1s) | 12 | Ẩn dưới mặt nước 3D (submerge animation), lao ra theo phương thẳng đứng bất ngờ trong bán kính 1.2m quanh nước | Không đứng yên gần nước quá 3s |
| Light Eater | 20 | 2.4 m/s | 5 lên người / -10 độ bền lên đuốc | Bay/lao thẳng theo đường ngắn nhất tới nguồn sáng, bỏ qua chướng ngại nhỏ | Tiêu diệt ưu tiên số 1 |
| Pack Runner | 18/con | 3.6 m/s | 6/con | Formation 3 con thực sự bao vây theo không gian (flanking), tận dụng vật cản để chia hướng tấn công | Tách đội đánh từng con |
| Shadow Creeper "Dập Tắt" (Khu 4) | 40 | 2.9 m/s | 8 + giảm độ bền đuốc theo thời gian | Bám theo Torch Bearer qua NavMesh, ưu tiên tiếp cận từ phía sau/góc khuất | Chủ động kéo/chặn trước khi áp sát 3s |

**Mật độ quái tối đa cùng lúc theo khu:** giữ nguyên bảng từ bản 2D (Khu 1: 3, Khu 2: 4–5, Khu 3: 6–7, Khu 4: 5–6 wave).

**Ghi chú kỹ thuật AI 3D:** Cần dùng `NavigationRegion3D` + `NavigationAgent3D` cho toàn bộ quái để pathfinding hoạt động đúng qua địa hình phức tạp (khác hẳn 2D chỉ cần vector di chuyển đơn giản). Đây là một trong những phần tốn công sức nhất khi chuyển 3D.

---

## 10. Tiến trình độ khó

Giữ nguyên đường cong từ bản 2D — chỉ thay đổi cách trải nghiệm được cảm nhận qua thị giác 3D thay vì UI/thanh trạng thái thuần túy.

| Thời gian | Mật độ quái | Độ bền đuốc trung bình còn lại | Cảm xúc mục tiêu |
|---|---|---|---|
| 0–4 phút (Khu 1) | Thấp-trung bình | 90–100% | Tò mò, làm quen không gian 3D và cơ chế |
| 4–10 phút (Khu 2) | Trung bình-cao | 55–75% | Bắt đầu căng thẳng, giao tiếp nhiều, cảnh giác về sương mù thể tích |
| 10–18 phút (Khu 3) | Cao | 25–45% | Mệt mỏi, tập trung cao độ, cảm giác không gian hẹp/tối rõ rệt |
| 18–26 phút (Khu 4) | Rất cao, không nghỉ | 10–25% | Căng thẳng tột độ, quái xuất hiện từ mọi hướng 3D |
| 26–30 phút (Boss Area) | Cực cao | 5–15% | Đỉnh điểm — nhìn thấy đích từ xa, "gần được rồi" |
| Khi thắng | — | — | Giải tỏa mạnh, camera có thể kéo rộng để lộ toàn cảnh chiến thắng |

---

## 11. Giao diện & Thông tin người chơi

- Thanh máu bản thân (góc dưới trái, HUD tối giản để không che khuất không gian 3D)
- Thanh độ bền đuốc — **bổ sung**: chính ngọn lửa 3D trên model đuốc đã thể hiện trực quan, thanh UI chỉ là backup rõ ràng hơn
- Biểu tượng/hào quang phát sáng phía trên đầu người đang cầm đuốc trong thế giới 3D, nhìn thấy từ xa qua vật cản nhẹ (silhouette outline)
- Chỉ báo % hành trình đã đi
- Số người còn sống
- Viền đỏ màn hình + rung camera nhẹ khi độ bền đuốc < 30 (mạnh hơn cảm giác so với bản 2D nhờ chiều sâu không gian)

---

## 12. Điều kiện thắng & thua

Giữ nguyên hoàn toàn logic từ bản 2D:

**Thắng:** Torch Bearer bước vào vòng tròn ánh sáng cuối cùng ở Boss Area.

**Thua (Game Over):**
1. Torch Bearer chết
2. Đuốc tắt hoàn toàn
3. Toàn bộ Guardian chết và hết 10–12 giây đếm ngược mà Torch Bearer chưa thoát vây

---

## 13. Flowchart logic game

Logic không đổi so với bản 2D (đây là logic thuần túy, không phụ thuộc chiều không gian):

```
[Bắt đầu Game] → [Chọn Torch Bearer đầu tiên]
	  │
	  ▼
┌───────────────────────────┐
│   VÒNG LẶP CHÍNH (mỗi frame)│
└───────────────────────────┘
	  │
	  ▼
[Cập nhật độ bền đuốc] → Độ bền = 0? ──Có──► [GAME OVER: Đuốc tắt]
	  │ Không
	  ▼
[Torch Bearer còn sống?] ──Không──► [GAME OVER: Torch Bearer chết]
	  │ Có
	  ▼
[Còn Guardian sống?]
	  ├─ Có ──► tiếp tục vòng lặp
	  └─ Không ──► [Đếm ngược 10–12s]
						├─ Thoát vây kịp giờ ──► hủy đếm ngược, tiếp tục
						└─ Hết giờ ──► [GAME OVER: Bị bao vây]
	  │
	  ▼
[Torch Bearer chạm vòng sáng Đích?] ──Có──► [CHIẾN THẮNG]
	  │ Không
	  ▼
[Quay lại đầu vòng lặp]
```

**Logic truyền đuốc (song song):**
```
[Giữ nút tương tác gần Torch Bearer]
	  │
	  ▼
[Khoảng cách < 1.5m?] ──Không──► Hủy
	  │ Có
	  ▼
[Đếm giữ nút 1.2s + animation trao tay] ── gián đoạn bởi: nhả nút / bị tấn công / ra khỏi 1.5m
	  │ Hoàn tất không gián đoạn
	  ▼
[Đổi vai trò: Torch Bearer cũ → Guardian, người nhận → Torch Bearer mới, PointLight chuyển sang model mới]
```

---

## 14. Cấu trúc Scene & Node — Godot 4.7 (3D)

```
Main.tscn
├── World (Node3D)
│   ├── Zone1_MistForest (Node3D, chứa MeshInstance3D địa hình + NavigationRegion3D)
│   ├── Zone2_Swamp
│   ├── Zone3_OldForestWindstorm
│   ├── Zone4_RuinedCastleFinalRoad
│   └── BossArea
│   [Mỗi Zone có: NavigationRegion3D riêng, WorldEnvironment con hoặc chia sẻ chung, các Area3D vùng sự kiện]
│
├── Players (Node3D) [MultiplayerSpawner]
│   └── PlayerCharacter.tscn (CharacterBody3D)
│       ├── MeshInstance3D + AnimationPlayer/AnimationTree (thay Sprite2D)
│       ├── CollisionShape3D (Capsule)
│       ├── SpringArm3D + Camera3D (camera bám sau nhân vật, tự tránh clipping)
│       ├── OmniLight3D (active khi là Torch Bearer, kèm particle ngọn lửa)
│       ├── StateMachine — Normal / CarryingTorch / Dead
│       ├── HealthComponent
│       ├── TorchComponent — độ bền, bán kính/energy ánh sáng, truyền đuốc (authority server-side)
│       ├── MultiplayerSynchronizer (đồng bộ Transform3D, animation state)
│       └── InteractionArea (Area3D) — nhặt vật phẩm, truyền đuốc, giữ cửa
│
├── Enemies (Node3D) [MultiplayerSpawner]
│   └── EnemyBase.tscn (CharacterBody3D)
│       ├── MeshInstance3D + AnimationPlayer
│       ├── NavigationAgent3D (bắt buộc — thay cho vector di chuyển đơn giản của bản 2D)
│       ├── AIController — behavior tree: Idle/Chase/Attack/Flee-from-light, tích hợp raycast kiểm tra che khuất
│       ├── LightDetectionArea (Area3D)
│       ├── HealthComponent
│       └── MultiplayerSynchronizer
│
├── GameManager (Node, Autoload)
│   ├── State toàn cục: đang chơi / thắng / thua
│   ├── Logic đếm ngược khi Guardian chết hết
│   ├── Chuyển zone, load Rest Point
│   └── Signal tới UI khi có sự kiện quan trọng
│
├── RestPointManager (Node, trong Rest Point scene)
│   └── Area3D kích hoạt hồi máu/độ bền khi player vào
│
├── WorldEnvironment (Node) — quản lý fog thể tích, tone mapping, ánh sáng môi trường tối thiểu để giữ độ tối cần thiết
│
└── UI (CanvasLayer, vẫn 2D overlay trên nền 3D)
	├── HealthBar, TorchDurabilityBar, TorchBearerIndicator
	├── ProgressIndicator, AliveCounter
	└── GameOverScreen / VictoryScreen
```

**Ghi chú kỹ thuật multiplayer (3D):**
- `MultiplayerSpawner` cho Players và Enemies giữ nguyên vai trò như bản 2D
- `TorchComponent` vẫn authority-only trên server/host
- **Khác biệt lớn nhất so với 2D:** cần đồng bộ thêm animation state qua `MultiplayerSynchronizer` (không chỉ vị trí), và `NavigationAgent3D` của quái vật cần chạy trên server để tránh desync giữa các client khi quái pathfinding qua địa hình phức tạp
- State "Dead" giữ buffer 0.5–1s trước khi loại người chơi khỏi gameplay để tránh false-positive do lag — quan trọng hơn ở 3D vì animation chết cần thời gian phát trọn vẹn

---

## 15. Phong cách hình ảnh & Phạm vi kỹ thuật (mục mới, đặc thù cho quyết định chuyển 3D)

### Vì sao chọn Low-poly stylized thay vì realistic
- Giảm đáng kể thời gian tạo model/texture — low-poly cho phép 1 người làm art vẫn ra sản phẩm nhất quán trong thời gian hợp lý
- Phong cách này đang phổ biến trong indie horror hiện tại, không bị đánh giá thấp về mặt thẩm mỹ nếu ánh sáng/bóng đổ được đầu tư tốt — ánh sáng chính là yếu tố quan trọng nhất của game này, không phải độ chi tiết model
- Có thể tận dụng asset pack low-poly có sẵn (nhân vật, cây cối, địa hình cơ bản) để rút ngắn thời gian, chỉ tự làm phần đặc trưng (quái vật, đuốc, các vật thể tương tác chính)

### Bắt buộc
- CharacterBody3D, NavigationRegion3D + NavigationAgent3D, OmniLight3D/SpotLight3D với shadow casting, MultiplayerSpawner + MultiplayerSynchronizer, State machine
- WorldEnvironment với fog thể tích để kiểm soát tầm nhìn và tạo độ sâu

### Nên có nhưng giữ đơn giản
- Hệ thống độ bền đuốc (mục 6), 5 loại quái với AI 3D nhẹ (mục 9), Rest Point như scene riêng
- Animation cơ bản: idle, walk, run, attack, hit, death, truyền đuốc — không cần blend tree phức tạp cho bản đầu

### Không nên làm ở bản đầu
- Hệ thống vật phẩm phức tạp, skill tree, procedural generation, voice chat tích hợp
- Facial animation, cloth/hair simulation, ragdoll physics phức tạp — không cần thiết cho gameplay và tốn nhiều thời gian
- Ánh sáng realistic (path tracing, lumen-tương-đương) — dùng ánh sáng stylized tối ưu hiệu năng cho multiplayer

---

## 16. Rủi ro cần theo dõi (cập nhật cho bản 3D)

- **Rủi ro lớn nhất: khối lượng công việc.** Nếu team không có 3D artist/animator, khuyến nghị nghiêm túc dùng asset pack có sẵn cho phần lớn model, chỉ tự làm những gì đặc trưng nhất (quái vật, đuốc)
- Nguy cơ độ khó quá cao dẫn tới tỷ lệ thua gần 100% ở những lần chơi đầu — vẫn cần hiệu chỉnh để người chơi kỹ năng trung bình có ~15–25% cơ hội thắng ở lần chơi thứ 5–10
- **Rủi ro kỹ thuật mới:** NavigationAgent3D cho nhiều quái cùng lúc (Khu 3 có tới 7–8 con) có thể gây hiệu năng kém nếu không tối ưu — cần profiling sớm, không để tới cuối dự án mới phát hiện
- **Rủi ro mới về networking:** đồng bộ animation 3D qua mạng dễ gây giật/lag hình ảnh hơn nhiều so với 2D — cần test multiplayer thật (không chỉ local) từ giai đoạn sớm của dự án, không để tới cuối
- Đoạn Khu 2→3→4 liên tục 22 phút không nghỉ vẫn có thể gây kiệt sức tinh thần thật cho người chơi — theo dõi qua playtest như bản 2D

---

## 17. Các phần có thể viết tiếp

1. Bảng thiết kế wave chi tiết cho Khu 4 (số lượng, loại quái, thời điểm spawn, hướng xuất hiện 3D)
2. Danh sách asset 3D cần thiết (model, animation) và ước tính nguồn (tự làm vs asset pack)
3. Kịch bản playtest cụ thể để hiệu chỉnh tỷ lệ thắng mục tiêu 15–25%
4. Thiết kế âm thanh 3D positional (quan trọng hơn nhiều so với bản 2D vì hướng âm thanh giúp định vị nguy hiểm)
5. Thiết kế vật phẩm hỗ trợ Guardian (đá lửa, bẫy tạm, bùa tăng tốc)
6. Kịch bản lore/narrative nền cho thế giới game
