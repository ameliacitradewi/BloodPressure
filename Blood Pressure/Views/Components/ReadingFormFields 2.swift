//
//  ReadingFormFields.swift
//  Blood Pressure
//

import SwiftUI
import SwiftData

struct ReadingFormFields2: View {
    @Binding var systolic: String
    @Binding var diastolic: String
    @Binding var pulse: String
    @Binding var date: Date
    @Binding var notes: String
    @Binding var position: MeasurementPosition
    @Binding var arm: ArmUsed
    
    let showValidationErrors: Bool
    
    private var shouldHighlightSystolic: Bool {
        showValidationErrors && systolic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var shouldHighlightDiastolic: Bool {
        showValidationErrors && diastolic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var shouldHighlightPulse: Bool {
        false
    }
    
    var body: some View {
        VStack(spacing: 14) {
            dateSection
            
            ReadingInputCard(
                title: "Systolic",
                subtitle: "Upper number",
                unit: "mmHg",
                placeholder: "70–250",
                text: $systolic,
                keyboardType: .numberPad,
                isHighlighted: shouldHighlightSystolic,
                validationText: "Enter 70–250"
            )
            
            ReadingInputCard(
                title: "Diastolic",
                subtitle: "Lower number",
                unit: "mmHg",
                placeholder: "40–150",
                text: $diastolic,
                keyboardType: .numberPad,
                isHighlighted: shouldHighlightDiastolic,
                validationText: "Enter 40–150"
            )
            
            ReadingInputCard(
                title: "Heart Rate",
                subtitle: "Pulse",
                unit: "bpm",
                placeholder: "30–200",
                text: $pulse,
                keyboardType: .numberPad,
                isHighlighted: shouldHighlightPulse,
                validationText: "Enter 30–200"
            )
            
            positionSection
            
            armSection
            
            NotesInputCard(notes: $notes)
        }
    }
    
    private var dateSection: some View {
        HStack(spacing: 14) {
            Text("Date & Time")
                .font(.system(.headline, weight: .bold))
                .foregroundStyle(Color(red: 0.09, green: 0.12, blue: 0.25))

            Spacer()
            
            DatePicker(
                "",
                selection: $date,
                displayedComponents: [.date, .hourAndMinute]
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .font(.system(.subheadline, weight: .semibold))
            .tint(Color(red: 0.12, green: 0.30, blue: 0.53))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 5)
        )
    }

    private var positionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Position")
                .font(.system(.headline, weight: .bold))
                .foregroundStyle(Color(red: 0.09, green: 0.12, blue: 0.25))

            HStack(spacing: 12) {
                positionOption(
                    title: "Sitting",
                    icon: "chair.lounge",
                    isSelected: position == .sitting
                ) {
                    position = .sitting
                }

                positionOption(
                    title: "Lying Down",
                    icon: "bed.double",
                    isSelected: position == .lyingDown
                ) {
                    position = .lyingDown
                }

                positionOption(
                    title: "Standing",
                    icon: "figure.stand",
                    isSelected: position == .standing
                ) {
                    position = .standing
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 5)
        )
    }

    private var armSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Arm Used")
                .font(.system(.headline, weight: .bold))
                .foregroundStyle(Color(red: 0.09, green: 0.12, blue: 0.25))

            HStack(spacing: 12) {
                armOption(
                    title: "Right Arm",
                    icon: "hand.point.right",
                    isSelected: arm == .rightArm
                ) {
                    arm = .rightArm
                }

                armOption(
                    title: "Left Arm",
                    icon: "hand.point.left",
                    isSelected: arm == .leftArm
                ) {
                    arm = .leftArm
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 5)
        )
    }
}

private struct ReadingInputCard: View {
    let title: String
    let subtitle: String
    let unit: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let isHighlighted: Bool
    let validationText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(.headline, weight: .bold))
                        .foregroundStyle(Color(red: 0.09, green: 0.12, blue: 0.25))
                    
                    Text(subtitle)
                        .font(.system(.subheadline, weight: .medium))
                        .foregroundStyle(Color(red: 0.43, green: 0.50, blue: 0.65))
                }
                
                Spacer()
                
                Text(unit)
                    .font(.system(.caption, weight: .medium))
                    .foregroundStyle(Color(red: 0.66, green: 0.72, blue: 0.83))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.12, green: 0.30, blue: 0.53))
                    .tint(Color(red: 0.12, green: 0.30, blue: 0.53))
                
                Rectangle()
                    .fill(isHighlighted ? Color(red: 1.0, green: 0.18, blue: 0.43) : Color(red: 0.87, green: 0.91, blue: 0.96))
                    .frame(height: isHighlighted ? 2 : 1)
                
                if isHighlighted {
                    Text(validationText)
                        .font(.system(.caption, weight: .medium))
                        .foregroundStyle(Color(red: 1.0, green: 0.18, blue: 0.43))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 5)
        )
    }
}

private struct NotesInputCard: View {
    @Binding var notes: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Note (optional)")
                .font(.system(.headline, weight: .bold))
                .foregroundStyle(Color(red: 0.09, green: 0.12, blue: 0.25))
            
            TextField("After exercise, feeling stressed...", text: $notes, axis: .vertical)
                .font(.system(.body, weight: .regular))
                .foregroundStyle(Color(red: 0.09, green: 0.12, blue: 0.25))
                .lineLimit(3...6)
        }
        .padding(20)
        .frame(minHeight: 118, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 5)
        )
    }
}

enum ReadingFormValidator {
    static func validate(systolic: String, diastolic: String, pulse: String) -> (Int, Int, Int?)? {
        guard let sys = Int(systolic), let dia = Int(diastolic) else { return nil }
        
        guard (50...300).contains(sys), (30...200).contains(dia), sys > dia else { return nil }
        
        if pulse.isEmpty {
            return (sys, dia, nil)
        }
        
        guard let pulseValue = Int(pulse), (30...220).contains(pulseValue) else { return nil }
        
        return (sys, dia, pulseValue)
    }
}

@ViewBuilder
private func positionOption(
    title: String,
    icon: String,
    isSelected: Bool,
    action: @escaping () -> Void
) -> some View {
    Button(action: action) {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(.title))

            Text(title)
                .font(.system(.caption, weight: .semibold))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(
            isSelected
            ? Color(red: 0.12, green: 0.30, blue: 0.53)
            : Color(red: 0.43, green: 0.50, blue: 0.65)
        )
        .frame(maxWidth: .infinity)
        .frame(height: 88)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(isSelected ? Color(red: 0.93, green: 0.95, blue: 0.98) : Color(red: 0.96, green: 0.97, blue: 0.99))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    isSelected
                    ? Color(AppTheme.accent)
                    : Color.clear,
                    lineWidth: 2
                )
        )
    }
    .buttonStyle(.plain)
}

@ViewBuilder
private func armOption(
    title: String,
    icon: String,
    isSelected: Bool,
    action: @escaping () -> Void
) -> some View {
    Button(action: action) {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(.title))

            Text(title)
                .font(.system(.caption, weight: .semibold))
        }
        .foregroundStyle(
            isSelected
            ? Color(red: 0.12, green: 0.30, blue: 0.53)
            : Color(red: 0.43, green: 0.50, blue: 0.65)
        )
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(isSelected ? Color(red: 0.93, green: 0.95, blue: 0.98) : Color(red: 0.96, green: 0.97, blue: 0.99))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    isSelected
                    ? Color(AppTheme.accent)
                    : Color.clear,
                    lineWidth: 2
                )
        )
    }
    .buttonStyle(.plain)
}
