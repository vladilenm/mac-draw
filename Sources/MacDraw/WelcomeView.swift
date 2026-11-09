import SwiftUI

struct WelcomeView: View {
    @ObservedObject var state: AppState
    var start: () -> Void
    private let cyan = Color(red: 0.08, green: 0.79, blue: 0.97)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 9) {
                Image(systemName: "pencil.tip.crop.circle.fill").font(.system(size: 25)).foregroundStyle(cyan)
                Text("Mac Draw").font(.system(size: 17, weight: .semibold))
                Spacer()
                Text("ПОВЕРХ ВАШЕГО ЭКРАНА").font(.system(size: 9, weight: .semibold)).tracking(1.6).foregroundStyle(.white.opacity(0.35))
            }
            .padding(.bottom, 34)
            Text("Покажите мысль.")
                .font(.system(size: 43, weight: .semibold, design: .rounded)).tracking(-1.8)
                .padding(.bottom, 12)
            Text("Стрелка, пара линий — и всё понятно.\nРисуйте прямо поверх браузера, кода и презентаций.")
                .font(.system(size: 15)).lineSpacing(5).foregroundStyle(.white.opacity(0.57))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 28)

            HStack(spacing: 24) {
                HStack(spacing: 7) {
                    keycap("⌃"); keycap("⌥"); keycap("D")
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text("Вызвать. Нарисовать. Скрыть.").font(.system(size: 14, weight: .semibold))
                    Text("Одно сочетание из любого приложения").font(.system(size: 11)).foregroundStyle(.white.opacity(0.4))
                }
                Spacer(minLength: 0)
            }
            .padding(19)
            .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(.white.opacity(0.07)))
            .padding(.bottom, 25)

            HStack(alignment: .top, spacing: 24) {
                tip("arrow.up.right", title: "Выделяйте главное", detail: "Перо, стрелки, фигуры\nи текст в один клик")
                tip("cursorarrow", title: "Продолжайте показ", detail: "Режим курсора оставит\nрисунки поверх окон")
                tip("arrow.uturn.backward", title: "Ошибаться можно", detail: "⌘Z отменяет действие\nEsc очищает холст")
            }
            .padding(.bottom, 26)

            if !state.hotKeyAvailable {
                Text("⌃⌥D занято другой программой. Открывайте панель через значок пера в строке меню.")
                    .font(.system(size: 11)).foregroundStyle(.orange).padding(.bottom, 12)
            }
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Для видео записывайте весь экран").foregroundStyle(.white.opacity(0.6))
                    Text("Рисунки хранятся до закрытия Mac Draw").foregroundStyle(.white.opacity(0.3))
                }.font(.system(size: 10.5))
                Spacer()
                Button(action: start) {
                    HStack(spacing: 9) {
                        Text("Начать рисовать")
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(red: 0.02, green: 0.12, blue: 0.15))
                    .padding(.horizontal, 18).frame(height: 42)
                    .background(cyan, in: RoundedRectangle(cornerRadius: 11))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(36)
        .padding(.top, 6)
        .frame(width: 640)
        .background(Color(red: 0.07, green: 0.08, blue: 0.1))
        .foregroundStyle(.white)
        .environment(\.colorScheme, .dark)
    }

    private func keycap(_ text: String) -> some View {
        Text(text).font(.system(size: 24, weight: .medium, design: .rounded))
            .frame(width: 43, height: 46)
            .background(.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 9))
            .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(.white.opacity(0.1)))
    }
    private func tip(_ symbol: String, title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol).font(.system(size: 18, weight: .medium)).foregroundStyle(cyan).frame(height: 24)
            Text(title).font(.system(size: 12, weight: .semibold))
            Text(detail).font(.system(size: 11)).lineSpacing(4).foregroundStyle(.white.opacity(0.4))
                .fixedSize(horizontal: false, vertical: true)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
