import SwiftUI

struct NetworkProfilesView: View {
    @StateObject private var viewModel = DIContainer.shared.makeNetworkProfileViewModel()
    @State private var showingCreateSheet = false
    @State private var showingEditSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                headerSection

                profilesList
            }
            .padding(AppSpacing.screenPadding)
        }
        .background(AppColors.backgroundApp)
        .sheet(isPresented: $showingCreateSheet) {
            NetworkProfileEditorView(
                profile: nil,
                onSave: { profile in
                    viewModel.createProfile(
                        name: profile.name,
                        purpose: profile.purpose,
                        networkType: profile.networkType,
                        subnet: profile.ipv4Config?.subnet ?? "",
                        gateway: profile.ipv4Config?.gateway
                    )
                    showingCreateSheet = false
                }
            )
        }
        .sheet(item: Binding(
            get: { viewModel.editingProfile },
            set: { if $0 == nil { showingEditSheet = false } }
        )) { profile in
            NetworkProfileEditorView(
                profile: profile,
                onSave: { updatedProfile in
                    viewModel.updateProfile(updatedProfile)
                    showingEditSheet = false
                }
            )
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Профили сетей")
                .font(AppTypography.screenTitle)
                .foregroundStyle(AppColors.textPrimary)

            if let activeProfile = viewModel.activeProfile {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppColors.statusSuccess)

                    Text("Активный профиль: \(activeProfile.name)")
                        .font(AppTypography.bodyStrong)
                        .foregroundStyle(AppColors.textPrimary)
                }
                .padding(AppSpacing.sm)
                .background(AppColors.statusSuccess.opacity(0.1))
                .cornerRadius(AppRadius.md)
            }
        }
    }

    private var profilesList: some View {
        VStack(spacing: AppSpacing.sm) {
            if viewModel.profiles.isEmpty {
                emptyState
            } else {
                ForEach(viewModel.profiles) { profile in
                    NetworkProfileRow(
                        profile: profile,
                        isActive: profile.id == viewModel.activeProfile?.id,
                        onActivate: { viewModel.setActiveProfile(profile) },
                        onEdit: { viewModel.startEditing(profile); showingEditSheet = true },
                        onDelete: { viewModel.deleteProfile(profile) }
                    )
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "network")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.textTertiary)

            Text("Нет профилей сетей")
                .font(AppTypography.bodyStrong)
                .foregroundStyle(AppColors.textPrimary)

            Text("Создайте первый профиль для управления конфигурацией сети")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                viewModel.createNewProfile()
                showingCreateSheet = true
            } label: {
                Text("Создать профиль")
                    .font(AppTypography.bodyStrong)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .background(AppColors.accentPrimary)
                    .cornerRadius(AppRadius.md)
            }
            .buttonStyle(.plain)
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity)
        .background(AppColors.backgroundCard)
        .cornerRadius(AppRadius.lg)
    }
}

struct NetworkProfileRow: View {
    let profile: NetworkProfile
    let isActive: Bool
    let onActivate: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(profile.name)
                        .font(AppTypography.bodyStrong)
                        .foregroundStyle(AppColors.textPrimary)

                    Text(profile.networkType.rawValue)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppColors.statusSuccess)
                }
            }

            if !profile.purpose.isEmpty {
                Text(profile.purpose)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(2)
            }

            if let subnet = profile.ipv4Config?.subnet {
                HStack(spacing: AppSpacing.xxs) {
                    Image(systemName: "network")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.textTertiary)

                    Text(subnet)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            HStack(spacing: AppSpacing.sm) {
                if !isActive {
                    Button("Активировать", action: onActivate)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.accentPrimary)
                        .buttonStyle(.plain)
                }

                Spacer()

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundStyle(AppColors.textSecondary)
                }
                .buttonStyle(.plain)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundStyle(AppColors.statusDanger)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.backgroundCard)
        .cornerRadius(AppRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .strokeBorder(
                    isActive ? AppColors.statusSuccess : Color.clear,
                    lineWidth: 2
                )
        )
    }
}

struct NetworkProfileEditorView: View {
    let profile: NetworkProfile?
    let onSave: (NetworkProfile) -> Void

    @State private var name: String
    @State private var purpose: String
    @State private var networkType: NetworkType
    @State private var subnet: String
    @State private var gateway: String
    @State private var errorMessage: String?

    @Environment(\.dismiss) private var dismiss

    private let viewModel: NetworkProfileViewModel

    init(profile: NetworkProfile?, onSave: @escaping (NetworkProfile) -> Void) {
        self.profile = profile
        self.onSave = onSave
        self.viewModel = NetworkProfileViewModel(repository: NetworkProfileRepository())

        _name = State(initialValue: profile?.name ?? "")
        _purpose = State(initialValue: profile?.purpose ?? "")
        _networkType = State(initialValue: profile?.networkType ?? .home)
        _subnet = State(initialValue: profile?.ipv4Config?.subnet ?? "")
        _gateway = State(initialValue: profile?.ipv4Config?.gateway ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    nameField
                    purposeField
                    networkTypePicker
                    subnetField
                    gatewayField

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.statusDanger)
                            .padding(AppSpacing.sm)
                            .background(AppColors.statusDanger.opacity(0.1))
                            .cornerRadius(AppRadius.md)
                    }

                    Button {
                        saveProfile()
                    } label: {
                        Text(profile == nil ? "Создать профиль" : "Сохранить изменения")
                            .font(AppTypography.bodyStrong)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.sm)
                            .background(AppColors.accentPrimary)
                            .cornerRadius(AppRadius.md)
                    }
                    .buttonStyle(.plain)
                    .disabled(name.isEmpty || !viewModel.validateSubnet(subnet))
                }
                .padding(AppSpacing.screenPadding)
            }
            .background(AppColors.backgroundApp)
            .navigationTitle(profile == nil ? "Новый профиль" : "Редактирование")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Название")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)

            TextField("Например: Домашняя сеть", text: $name)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
                .padding(AppSpacing.sm)
                .background(AppColors.backgroundElevated)
                .cornerRadius(AppRadius.md)
        }
    }

    private var purposeField: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Назначение")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)

            TextField("Описание использования сети", text: $purpose)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
                .padding(AppSpacing.sm)
                .background(AppColors.backgroundElevated)
                .cornerRadius(AppRadius.md)
        }
    }

    private var networkTypePicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Тип сети")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)

            Picker("Тип сети", selection: $networkType) {
                ForEach(NetworkType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var subnetField: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Подсеть (CIDR)")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)

            TextField("192.168.1.0/24", text: $subnet)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .autocorrectionDisabled()
                .padding(AppSpacing.sm)
                .background(AppColors.backgroundElevated)
                .cornerRadius(AppRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .strokeBorder(
                            viewModel.validateSubnet(subnet) ? AppColors.borderSubtle : AppColors.statusDanger,
                            lineWidth: 1
                        )
                )

            Text("Формат: адрес/префикс, например 192.168.1.0/24")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
    }

    private var gatewayField: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Шлюз (опционально)")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)

            TextField("192.168.1.1", text: $gateway)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .autocorrectionDisabled()
                .padding(AppSpacing.sm)
                .background(AppColors.backgroundElevated)
                .cornerRadius(AppRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .strokeBorder(
                            (gateway.isEmpty || viewModel.validateIPAddress(gateway)) ? AppColors.borderSubtle : AppColors.statusDanger,
                            lineWidth: 1
                        )
                )
        }
    }

    private func saveProfile() {
        guard !name.isEmpty else {
            errorMessage = "Название профиля обязательно"
            return
        }

        guard viewModel.validateSubnet(subnet) else {
            errorMessage = "Некорректная подсеть"
            return
        }

        guard gateway.isEmpty || viewModel.validateIPAddress(gateway) else {
            errorMessage = "Некорректный шлюз"
            return
        }

        let ipv4Config = IPv4Configuration(
            subnet: subnet,
            gateway: gateway.isEmpty ? nil : gateway
        )

        let updatedProfile = NetworkProfile(
            id: profile?.id ?? UUID(),
            name: name,
            purpose: purpose,
            networkType: networkType,
            ipv4Config: ipv4Config,
            segments: profile?.segments ?? [],
            infrastructure: profile?.infrastructure ?? [],
            isActive: profile?.isActive ?? false,
            createdAt: profile?.createdAt ?? Date(),
            updatedAt: Date()
        )

        onSave(updatedProfile)
    }
}

#Preview {
    NavigationStack {
        NetworkProfilesView()
    }
}
