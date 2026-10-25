import SwiftUI

struct StrainView: View {
    @ObservedObject var health: HealthStore

    private var result: StrainResult {
        StrainEngine.score(
            workouts: health.workouts,
            heartRateSamples: health.heartRate.map { [$0] } ?? []
        )
    }

    var body: some View {
        let result = result

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("STRAIN")
                        .font(.caption.bold())
                        .tracking(2)
                        .foregroundStyle(Color.pulseLime)

                    Text(
                        result.score.map {
                            String(Int($0.rounded()))
                        } ?? "—"
                    )
                    .font(.system(size: 68, weight: .bold, design: .rounded))

                    Text("de 21 · esfuerzo diario")
                        .foregroundStyle(Color.pulseMuted)

                    Text(result.explanation)
                        .font(.subheadline)
                        .foregroundStyle(Color.pulseMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(22)
                .background(
                    Color.pulseCard,
                    in: RoundedRectangle(cornerRadius: 22)
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("¿CÓMO SE CALCULA?")
                        .font(.caption.bold())
                        .tracking(1.5)
                        .foregroundStyle(Color.pulseMuted)

                    Text(
                        "PULSE 21 estima el esfuerzo a partir de la duración " +
                        "e intensidad de los entrenamientos registrados en Apple Salud " +
                        "y de las muestras cardíacas disponibles. La puntuación es " +
                        "orientativa y no utiliza el algoritmo propietario de WHOOP."
                    )
                    .font(.subheadline)
                    .foregroundStyle(Color.pulseMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(
                    Color.pulseCard,
                    in: RoundedRectangle(cornerRadius: 22)
                )
            }
            .padding(20)
        }
        .background(Color.pulseBackground.ignoresSafeArea())
        .navigationTitle("Esfuerzo")
        .navigationBarTitleDisplayMode(.inline)
    }
}
