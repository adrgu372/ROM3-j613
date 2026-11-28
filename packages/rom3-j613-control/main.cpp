#include <QApplication>
#include <QCheckBox>
#include <QDateTime>
#include <QFile>
#include <QFileInfo>
#include <QFont>
#include <QFontDatabase>
#include <QFrame>
#include <QGuiApplication>
#include <QHBoxLayout>
#include <QLabel>
#include <QListWidget>
#include <QMainWindow>
#include <QMessageBox>
#include <QPlainTextEdit>
#include <QProcess>
#include <QProcessEnvironment>
#include <QProgressBar>
#include <QPushButton>
#include <QScrollArea>
#include <QSettings>
#include <QStackedWidget>
#include <QStatusBar>
#include <QStyleHints>
#include <QTextCursor>
#include <QVBoxLayout>
#include <QWidget>

class MainWindow final : public QMainWindow {
public:
    MainWindow() {
        setWindowTitle("ROM3 Control Center");
        setMinimumSize(940, 680);
        resize(1100, 760);

        auto *shell = new QFrame(this);
        shell->setObjectName("shell");
        auto *shellLayout = new QHBoxLayout(shell);
        shellLayout->setContentsMargins(0, 0, 0, 0);
        shellLayout->setSpacing(0);

        shellLayout->addWidget(buildSidebar(shell));
        shellLayout->addWidget(buildContent(shell), 1);
        setCentralWidget(shell);

        statusBar()->showMessage("Ready");
        connectSignals();

        QSettings settings;
        const bool systemDark =
            QGuiApplication::styleHints()->colorScheme() ==
            Qt::ColorScheme::Dark;
        darkMode = settings.value("interface/darkMode", systemDark).toBool();
        applyTheme();
        refreshStatus();
    }

private:
    bool darkMode = false;

    QListWidget *navigation{};
    QStackedWidget *pages{};
    QLabel *pageTitle{};
    QLabel *pageSubtitle{};
    QLabel *healthSummary{};
    QLabel *sidebarKernel{};
    QLabel *kernelLabel{};
    QLabel *bootLabel{};
    QLabel *systemFirmwareLabel{};
    QLabel *componentFirmwareLabel{};
    QLabel *packageLabel{};
    QPushButton *checkButton{};
    QPushButton *applyButton{};
    QPushButton *githubCheckButton{};
    QPushButton *githubApplyButton{};
    QPushButton *verifyButton{};
    QPushButton *refreshButton{};
    QPushButton *themeButton{};
    QCheckBox *autoCheck{};
    QPushButton *saveAutoButton{};
    QProgressBar *progress{};
    QPlainTextEdit *output{};
    QProcess process;

    static QFrame *newCard(QWidget *parent) {
        auto *card = new QFrame(parent);
        card->setProperty("card", true);
        return card;
    }

    static QLabel *newLabel(const QString &text, QWidget *parent,
                            const char *property = nullptr) {
        auto *label = new QLabel(text, parent);
        label->setWordWrap(true);
        if (property)
            label->setProperty(property, true);
        return label;
    }

    static QWidget *infoRow(const QString &name, QLabel **value,
                            QWidget *parent) {
        auto *row = new QWidget(parent);
        auto *layout = new QHBoxLayout(row);
        layout->setContentsMargins(0, 5, 0, 5);
        layout->setSpacing(16);
        auto *key = newLabel(name, row, "muted");
        key->setMinimumWidth(180);
        *value = newLabel("Checking...", row, "value");
        (*value)->setTextInteractionFlags(Qt::TextSelectableByMouse);
        layout->addWidget(key);
        layout->addWidget(*value, 1);
        return row;
    }

    QFrame *buildSidebar(QWidget *parent) {
        auto *sidebar = new QFrame(parent);
        sidebar->setObjectName("sidebar");
        sidebar->setFixedWidth(238);
        auto *layout = new QVBoxLayout(sidebar);
        layout->setContentsMargins(18, 22, 18, 18);
        layout->setSpacing(18);

        auto *brandRow = new QHBoxLayout();
        brandRow->setSpacing(12);
        auto *mark = new QLabel("R3", sidebar);
        mark->setObjectName("brandMark");
        mark->setAlignment(Qt::AlignCenter);
        mark->setFixedSize(44, 44);
        auto *brandText = new QVBoxLayout();
        brandText->setSpacing(1);
        auto *brand = new QLabel("ROM3", sidebar);
        brand->setObjectName("brandTitle");
        auto *edition = new QLabel("J613 Control Center", sidebar);
        edition->setProperty("muted", true);
        brandText->addWidget(brand);
        brandText->addWidget(edition);
        brandRow->addWidget(mark);
        brandRow->addLayout(brandText, 1);
        layout->addLayout(brandRow);

        navigation = new QListWidget(sidebar);
        navigation->setObjectName("navigation");
        navigation->setFocusPolicy(Qt::NoFocus);
        navigation->setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
        navigation->addItem("Updates");
        navigation->addItem("System");
        navigation->addItem("Activity");
        navigation->setCurrentRow(0);
        layout->addWidget(navigation);
        layout->addStretch();

        auto *stateCard = new QFrame(sidebar);
        stateCard->setProperty("sidebarCard", true);
        auto *stateLayout = new QVBoxLayout(stateCard);
        stateLayout->setContentsMargins(14, 13, 14, 13);
        stateLayout->setSpacing(6);
        auto *stateBadge = newLabel("ROM3 TESTED", stateCard, "badge");
        stateBadge->setAlignment(Qt::AlignCenter);
        sidebarKernel = newLabel("Kernel: checking...", stateCard, "muted");
        stateLayout->addWidget(stateBadge);
        stateLayout->addWidget(sidebarKernel);
        layout->addWidget(stateCard);

        themeButton = new QPushButton(sidebar);
        themeButton->setProperty("secondary", true);
        layout->addWidget(themeButton);
        return sidebar;
    }

    QWidget *buildContent(QWidget *parent) {
        auto *content = new QFrame(parent);
        content->setObjectName("content");
        auto *layout = new QVBoxLayout(content);
        layout->setContentsMargins(32, 26, 32, 18);
        layout->setSpacing(14);

        auto *header = new QHBoxLayout();
        auto *heading = new QVBoxLayout();
        heading->setSpacing(3);
        pageTitle = new QLabel(content);
        pageTitle->setObjectName("pageTitle");
        pageSubtitle = newLabel("", content, "muted");
        heading->addWidget(pageTitle);
        heading->addWidget(pageSubtitle);
        header->addLayout(heading, 1);

        refreshButton = new QPushButton("Refresh", content);
        refreshButton->setProperty("secondary", true);
        header->addWidget(refreshButton, 0, Qt::AlignTop);
        layout->addLayout(header);

        progress = new QProgressBar(content);
        progress->setRange(0, 1);
        progress->setValue(1);
        progress->setTextVisible(false);
        layout->addWidget(progress);

        pages = new QStackedWidget(content);
        pages->addWidget(buildUpdatesPage(pages));
        pages->addWidget(buildSystemPage(pages));
        pages->addWidget(buildActivityPage(pages));
        layout->addWidget(pages, 1);

        connect(navigation, &QListWidget::currentRowChanged, this,
                [this](int row) {
            pages->setCurrentIndex(row);
            updatePageHeading(row);
        });
        updatePageHeading(0);
        return content;
    }

    QWidget *buildUpdatesPage(QWidget *parent) {
        auto *scroll = new QScrollArea(parent);
        scroll->setWidgetResizable(true);
        scroll->setFrameShape(QFrame::NoFrame);

        auto *page = new QWidget(scroll);
        auto *layout = new QVBoxLayout(page);
        layout->setContentsMargins(0, 2, 0, 16);
        layout->setSpacing(12);

        auto *overview = newCard(page);
        auto *overviewLayout = new QVBoxLayout(overview);
        overviewLayout->setContentsMargins(20, 17, 20, 17);
        overviewLayout->setSpacing(7);
        auto *overviewTop = new QHBoxLayout();
        auto *overviewTitle = newLabel("System protected", overview, "cardTitle");
        auto *overviewBadge = newLabel("READY", overview, "badge");
        overviewTop->addWidget(overviewTitle);
        overviewTop->addStretch();
        overviewTop->addWidget(overviewBadge);
        overviewLayout->addLayout(overviewTop);
        healthSummary = newLabel("Checking the installed ROM3 stack...", overview,
                                "muted");
        overviewLayout->addWidget(healthSummary);
        layout->addWidget(overview);

        auto *safe = newCard(page);
        auto *safeLayout = new QVBoxLayout(safe);
        safeLayout->setContentsMargins(20, 17, 20, 17);
        safeLayout->setSpacing(7);
        safeLayout->addWidget(newLabel("Safe Arch updates", safe, "cardTitle"));
        safeLayout->addWidget(newLabel(
            "Update ordinary Arch packages while the tested kernel, "
            "bootloader, graphics, audio and compositor stack remain pinned.",
            safe, "muted"));
        auto *safeActions = new QHBoxLayout();
        safeActions->setSpacing(8);
        checkButton = new QPushButton("Check safe updates", safe);
        checkButton->setProperty("secondary", true);
        applyButton = new QPushButton("Apply safe updates", safe);
        applyButton->setProperty("primary", true);
        safeActions->addStretch();
        safeActions->addWidget(checkButton);
        safeActions->addWidget(applyButton);
        safeLayout->addLayout(safeActions);
        layout->addWidget(safe);

        auto *signedCard = newCard(page);
        auto *signedLayout = new QVBoxLayout(signedCard);
        signedLayout->setContentsMargins(20, 17, 20, 17);
        signedLayout->setSpacing(7);
        signedLayout->addWidget(
            newLabel("Signed ROM3 releases", signedCard, "cardTitle"));
        signedLayout->addWidget(newLabel(
            "Discover, authenticate and install tested protected package "
            "updates published on GitHub.",
            signedCard, "muted"));
        auto *signedActions = new QHBoxLayout();
        signedActions->setSpacing(8);
        githubCheckButton = new QPushButton("Check ROM3 release", signedCard);
        githubCheckButton->setProperty("secondary", true);
        githubApplyButton = new QPushButton("Install ROM3 release", signedCard);
        githubApplyButton->setProperty("primary", true);
        signedActions->addStretch();
        signedActions->addWidget(githubCheckButton);
        signedActions->addWidget(githubApplyButton);
        signedLayout->addLayout(signedActions);
        layout->addWidget(signedCard);

        auto *automatic = newCard(page);
        auto *automaticLayout = new QHBoxLayout(automatic);
        automaticLayout->setContentsMargins(20, 15, 20, 15);
        automaticLayout->setSpacing(12);
        auto *autoText = new QVBoxLayout();
        autoText->setSpacing(3);
        autoText->addWidget(newLabel("Automatic updates", automatic, "cardTitle"));
        autoText->addWidget(newLabel(
            "Check for signed ROM3 releases daily. Reboots are never automatic.",
            automatic, "muted"));
        autoCheck = new QCheckBox(automatic);
        saveAutoButton = new QPushButton("Save setting", automatic);
        saveAutoButton->setProperty("secondary", true);
        automaticLayout->addLayout(autoText, 1);
        automaticLayout->addWidget(autoCheck);
        automaticLayout->addWidget(saveAutoButton);
        layout->addWidget(automatic);
        layout->addStretch();

        scroll->setWidget(page);
        return scroll;
    }

    QWidget *buildSystemPage(QWidget *parent) {
        auto *page = new QWidget(parent);
        auto *layout = new QVBoxLayout(page);
        layout->setContentsMargins(0, 2, 0, 16);
        layout->setSpacing(12);

        auto *identity = newCard(page);
        auto *identityLayout = new QVBoxLayout(identity);
        identityLayout->setContentsMargins(20, 17, 20, 17);
        identityLayout->setSpacing(6);
        identityLayout->addWidget(
            newLabel("Installed system", identity, "cardTitle"));
        identityLayout->addWidget(infoRow("Linux kernel", &kernelLabel, identity));
        identityLayout->addWidget(infoRow("ROM3 bootloader", &bootLabel, identity));
        identityLayout->addWidget(
            infoRow("Apple system firmware", &systemFirmwareLabel, identity));
        identityLayout->addWidget(
            infoRow("Apple component firmware", &componentFirmwareLabel, identity));
        identityLayout->addWidget(
            infoRow("Protected package set", &packageLabel, identity));
        layout->addWidget(identity);

        auto *actions = newCard(page);
        auto *actionsLayout = new QVBoxLayout(actions);
        actionsLayout->setContentsMargins(20, 17, 20, 17);
        actionsLayout->setSpacing(8);
        actionsLayout->addWidget(
            newLabel("Diagnostics", actions, "cardTitle"));
        actionsLayout->addWidget(newLabel(
            "Verify the kernel, GPU render nodes, device tree handoff, "
            "audio stack and speaker protection service.",
            actions, "muted"));
        auto *actionRow = new QHBoxLayout();
        verifyButton = new QPushButton("Verify live system", actions);
        verifyButton->setProperty("primary", true);
        actionRow->addStretch();
        actionRow->addWidget(verifyButton);
        actionsLayout->addLayout(actionRow);
        layout->addWidget(actions);
        layout->addStretch();
        return page;
    }

    QWidget *buildActivityPage(QWidget *parent) {
        auto *page = new QWidget(parent);
        auto *layout = new QVBoxLayout(page);
        layout->setContentsMargins(0, 2, 0, 12);
        layout->setSpacing(10);

        auto *card = newCard(page);
        auto *cardLayout = new QVBoxLayout(card);
        cardLayout->setContentsMargins(16, 14, 16, 16);
        cardLayout->setSpacing(8);
        cardLayout->addWidget(
            newLabel("Operation output", card, "cardTitle"));
        output = new QPlainTextEdit(card);
        output->setReadOnly(true);
        output->setFont(QFontDatabase::systemFont(QFontDatabase::FixedFont));
        output->setPlaceholderText(
            "Start an update or verification to see detailed output.");
        cardLayout->addWidget(output, 1);
        layout->addWidget(card, 1);
        return page;
    }

    void connectSignals() {
        connect(themeButton, &QPushButton::clicked, this, [this] {
            darkMode = !darkMode;
            QSettings().setValue("interface/darkMode", darkMode);
            applyTheme();
        });
        connect(checkButton, &QPushButton::clicked, this, [this] {
            runRootUpdate("Safe update check", "--check-safe");
        });
        connect(applyButton, &QPushButton::clicked, this, [this] {
            const auto answer = QMessageBox::question(
                this, "Apply safe updates",
                "Update ordinary packages while keeping every protected ROM3 "
                "package at its tested version?",
                QMessageBox::Yes | QMessageBox::No, QMessageBox::No);
            if (answer == QMessageBox::Yes)
                runRootUpdate("Safe update", "--apply-safe");
        });
        connect(githubCheckButton, &QPushButton::clicked, this, [this] {
            runRootProgram("Check signed ROM3 release",
                           "/usr/bin/rom3-j613-github-update", {"--check"});
        });
        connect(githubApplyButton, &QPushButton::clicked, this, [this] {
            const auto answer = QMessageBox::question(
                this, "Install signed ROM3 release",
                "Download, authenticate and install the newest signed ROM3 "
                "release from GitHub?",
                QMessageBox::Yes | QMessageBox::No, QMessageBox::No);
            if (answer == QMessageBox::Yes)
                runRootProgram("Install signed ROM3 release",
                               "/usr/bin/rom3-j613-github-update", {"--apply"});
        });
        connect(saveAutoButton, &QPushButton::clicked, this, [this] {
            runRootProgram(
                "Save automatic update setting",
                "/usr/bin/rom3-j613-github-update",
                {"--set-auto", autoCheck->isChecked() ? "on" : "off"});
        });
        connect(verifyButton, &QPushButton::clicked, this, [this] {
            runProcess("Live system verification",
                       "/usr/share/rom3-j613/verify-live-system.sh", {});
        });
        connect(refreshButton, &QPushButton::clicked,
                this, [this] { refreshStatus(); });

        connect(&process, &QProcess::readyReadStandardOutput,
                this, [this] { appendProcessOutput(); });
        connect(&process, &QProcess::finished, this,
                [this](int exitCode, QProcess::ExitStatus status) {
            appendProcessOutput();
            setBusy(false);
            const bool success =
                status == QProcess::NormalExit && exitCode == 0;
            if (success) {
                output->appendPlainText(
                    QString("\n[%1] Finished (exit 0)")
                        .arg(QDateTime::currentDateTime().toString(
                            "HH:mm:ss")));
                statusBar()->showMessage("Operation completed");
            } else {
                const QString log = output->toPlainText();
                QString reason;
                if (exitCode == 75 ||
                    log.contains("insufficient free space",
                                 Qt::CaseInsensitive)) {
                    reason =
                        "Insufficient free space. The rollback snapshot "
                        "could not be created safely, so no packages were changed.";
                } else if (exitCode == 74 ||
                           log.contains("swapfile",
                                        Qt::CaseInsensitive)) {
                    reason =
                        "The configured swapfile is missing, empty, truncated "
                        "or inactive. The update was cancelled before changing packages.";
                } else if (log.contains("rollback snapshot",
                                        Qt::CaseInsensitive) ||
                           log.contains("Btrfs",
                                        Qt::CaseInsensitive)) {
                    reason =
                        "The rollback snapshot could not be created. "
                        "No packages were changed.";
                } else if (exitCode == 126 || exitCode == 127) {
                    reason =
                        "Authentication was cancelled or permission was denied.";
                } else {
                    reason =
                        "The operation failed. Review the detailed activity log.";
                }
                output->appendPlainText(
                    QString("\n[%1] Failed: %2 (exit %3)")
                        .arg(QDateTime::currentDateTime().toString(
                                 "HH:mm:ss"),
                             reason)
                        .arg(exitCode));
                statusBar()->showMessage(reason);
                QMessageBox::warning(this, "Operation failed", reason);
            }
            refreshStatus();
        });
        connect(&process, &QProcess::errorOccurred, this,
                [this](QProcess::ProcessError error) {
            if (error == QProcess::FailedToStart) {
                appendProcessOutput();
                setBusy(false);
                QMessageBox::critical(
                    this, "Could not start operation",
                    "The requested program could not be started.");
            }
        });
    }

    void updatePageHeading(int row) {
        static const char *titles[] = {
            "Software Update", "System Information", "Activity"
        };
        static const char *subtitles[] = {
            "Safe updates and signed ROM3 releases",
            "Hardware stack, firmware and diagnostics",
            "Detailed command output and recovery information"
        };
        pageTitle->setText(titles[row]);
        pageSubtitle->setText(subtitles[row]);
    }

    static QString readProperty(const QString &path) {
        QFile file(path);
        if (!file.open(QIODevice::ReadOnly))
            return "unavailable";
        QByteArray data = file.readAll();
        while (data.endsWith('\0'))
            data.chop(1);
        return QString::fromUtf8(data).trimmed();
    }

    static QString commandOutput(const QString &program,
                                 const QStringList &arguments) {
        QProcess command;
        command.setProcessChannelMode(QProcess::MergedChannels);
        command.start(program, arguments);
        if (!command.waitForStarted(1500) ||
            !command.waitForFinished(4000))
            return {};
        if (command.exitStatus() != QProcess::NormalExit ||
            command.exitCode() != 0)
            return {};
        return QString::fromUtf8(command.readAll()).trimmed();
    }

    void refreshStatus() {
        const QString kernel = readProperty("/proc/sys/kernel/osrelease");
        kernelLabel->setText(kernel);
        kernelLabel->setToolTip(kernel);
        sidebarKernel->setText(
            QString("Kernel %1\nApple J613 · ROM3").arg(kernel));
        bootLabel->setText(readProperty(
            "/sys/firmware/devicetree/base/chosen/"
            "asahi,m1n1-stage2-version"));
        systemFirmwareLabel->setText(readProperty(
            "/sys/firmware/devicetree/base/chosen/"
            "asahi,system-fw-version"));
        componentFirmwareLabel->setText(readProperty(
            "/sys/firmware/devicetree/base/chosen/"
            "asahi,os-fw-version"));

        QString packages = commandOutput(
            "/usr/bin/pacman",
            {"-Q", "linux-rom3", "rom3", "mesa-rom3",
             "pipewire", "kwin", "rom3-j613-meta"});
        if (packages.isEmpty()) {
            packages = commandOutput(
                "/usr/bin/pacman",
                {"-Q", "linux-aurora", "aura", "mesa-aurora",
                 "pipewire", "kwin", "rom3-j613-meta"});
        }
        packageLabel->setText(packages.isEmpty() ? "unavailable" : packages);
        packageLabel->setToolTip(packages);
        healthSummary->setText(
            packages.isEmpty()
                ? "The protected package information could not be read."
                : QString("Kernel %1 · bootloader, graphics, audio and "
                          "compositor packages are protected by ROM3.")
                      .arg(kernel));

        QFile automatic("/etc/rom3-j613/auto-update.conf");
        bool enabled = false;
        if (automatic.open(QIODevice::ReadOnly))
            enabled = automatic.readAll().contains("AUTO_UPDATE=1");
        autoCheck->setChecked(enabled);
    }

    void runRootUpdate(const QString &title, const QString &mode) {
        runRootProgram(title, "/usr/bin/rom3-j613-update", {mode});
    }

    void runRootProgram(const QString &title, const QString &program,
                        const QStringList &arguments) {
        QStringList rootArguments{program};
        rootArguments.append(arguments);
        runProcess(title, "/usr/bin/pkexec", rootArguments);
    }

    void runProcess(const QString &title, const QString &program,
                    const QStringList &arguments) {
        if (process.state() != QProcess::NotRunning)
            return;
        if (!QFileInfo::exists(program)) {
            QMessageBox::critical(
                this, "Missing program",
                QString("Required program is missing:\n%1").arg(program));
            return;
        }

        navigation->setCurrentRow(2);
        output->clear();
        output->appendPlainText(
            QString("[%1] %2\n$ %3 %4\n")
                .arg(QDateTime::currentDateTime().toString("HH:mm:ss"),
                     title, program, arguments.join(' ')));
        setBusy(true);
        statusBar()->showMessage(title + "...");

        QProcessEnvironment environment =
            QProcessEnvironment::systemEnvironment();
        environment.insert("LC_ALL", "C");
        process.setProcessEnvironment(environment);
        process.setProcessChannelMode(QProcess::MergedChannels);
        process.start(program, arguments);
    }

    void appendProcessOutput() {
        const QString text = QString::fromLocal8Bit(process.readAll());
        if (!text.isEmpty()) {
            output->moveCursor(QTextCursor::End);
            output->insertPlainText(text);
        }
    }

    void setBusy(bool busy) {
        checkButton->setEnabled(!busy);
        applyButton->setEnabled(!busy);
        githubCheckButton->setEnabled(!busy);
        githubApplyButton->setEnabled(!busy);
        verifyButton->setEnabled(!busy);
        refreshButton->setEnabled(!busy);
        autoCheck->setEnabled(!busy);
        saveAutoButton->setEnabled(!busy);
        progress->setRange(0, busy ? 0 : 1);
        progress->setValue(busy ? 0 : 1);
    }

    void applyTheme() {
        themeButton->setText(darkMode ? "Light appearance" : "Dark appearance");
        setStyleSheet(darkMode ? darkStyle() : lightStyle());
    }

    static QString commonStyle() {
        return R"(
            QFrame#shell { border: none; }
            QLabel { background: transparent; }
            QLabel[cardTitle="true"] { font-size: 15px; font-weight: 600; }
            QLabel[badge="true"] {
                font-size: 10px;
                font-weight: 700;
                padding: 5px 9px;
                border-radius: 10px;
            }
            QPushButton {
                min-height: 20px;
                padding: 7px 13px;
                border-radius: 8px;
                font-weight: 600;
            }
            QPushButton:disabled { opacity: 0.45; }
            QCheckBox { spacing: 8px; }
            QCheckBox::indicator {
                width: 18px;
                height: 18px;
                border-radius: 5px;
            }
            QPlainTextEdit {
                border-radius: 9px;
                padding: 10px;
                selection-background-color: #0a84ff;
            }
            QProgressBar {
                min-height: 4px;
                max-height: 4px;
                border: none;
                border-radius: 2px;
            }
            QProgressBar::chunk { border-radius: 2px; }
            QMessageBox { min-width: 420px; }
            QStatusBar { border-top: 1px solid; }
            QScrollArea { background: transparent; border: none; }
            QScrollArea > QWidget > QWidget { background: transparent; }
        )";
    }

    static QString lightStyle() {
        return commonStyle() + R"(
            QFrame#shell, QFrame#content, QStackedWidget {
                background: #f5f5f7;
                color: #1d1d1f;
            }
            QFrame#sidebar {
                background: #e9e9ee;
                border-right: 1px solid #d1d1d6;
            }
            QLabel { color: #1d1d1f; }
            QLabel[muted="true"] { color: #6e6e73; font-size: 12px; }
            QLabel[value="true"] { color: #3a3a3c; font-size: 12px; }
            QLabel#brandTitle { font-size: 20px; font-weight: 700; }
            QLabel#brandMark {
                color: white;
                background: #007aff;
                border-radius: 12px;
                font-weight: 800;
                font-size: 16px;
            }
            QLabel#pageTitle { font-size: 24px; font-weight: 700; }
            QLabel[badge="true"] {
                color: #087a55;
                background: #d9f5e9;
                border: 1px solid #b8ead8;
            }
            QFrame[card="true"] {
                background: white;
                border: 1px solid #e2e2e7;
                border-radius: 12px;
            }
            QFrame[sidebarCard="true"] {
                background: rgba(255,255,255,0.72);
                border: 1px solid #d7d7dc;
                border-radius: 11px;
            }
            QListWidget#navigation {
                background: transparent;
                border: none;
                outline: none;
                font-size: 13px;
                color: #3a3a3c;
            }
            QListWidget#navigation::item {
                padding: 10px 12px;
                margin: 2px 0;
                border-radius: 8px;
            }
            QListWidget#navigation::item:hover:!selected {
                background: rgba(0,0,0,0.05);
            }
            QListWidget#navigation::item:selected {
                color: white;
                background: #007aff;
                font-weight: 600;
            }
            QPushButton {
                color: #1d1d1f;
                background: white;
                border: 1px solid #d1d1d6;
            }
            QPushButton:hover { background: #f2f2f7; }
            QPushButton[primary="true"] {
                color: white;
                background: #007aff;
                border-color: #007aff;
            }
            QPushButton[primary="true"]:hover { background: #0066d6; }
            QPushButton[secondary="true"] { background: white; }
            QCheckBox { color: #3a3a3c; }
            QCheckBox::indicator {
                border: 1px solid #b8b8be;
                background: white;
            }
            QCheckBox::indicator:checked {
                background: #007aff;
                border-color: #007aff;
            }
            QPlainTextEdit {
                color: #2c2c2e;
                background: #fafafa;
                border: 1px solid #e2e2e7;
            }
            QProgressBar { background: #dedee3; }
            QProgressBar::chunk { background: #007aff; }
            QStatusBar {
                color: #6e6e73;
                background: #f5f5f7;
                border-color: #dedee3;
            }
            QMessageBox, QMessageBox QLabel {
                background: #f5f5f7;
                color: #1d1d1f;
            }
            QMessageBox QPushButton {
                min-width: 82px;
            }
        )";
    }

    static QString darkStyle() {
        return commonStyle() + R"(
            QFrame#shell, QFrame#content, QStackedWidget {
                background: #1c1c1e;
                color: #f5f5f7;
            }
            QFrame#sidebar {
                background: #242426;
                border-right: 1px solid #343438;
            }
            QLabel { color: #f5f5f7; }
            QLabel[muted="true"] { color: #98989d; font-size: 12px; }
            QLabel[value="true"] { color: #d1d1d6; font-size: 12px; }
            QLabel#brandTitle { font-size: 20px; font-weight: 700; }
            QLabel#brandMark {
                color: white;
                background: #0a84ff;
                border-radius: 12px;
                font-weight: 800;
                font-size: 16px;
            }
            QLabel#pageTitle { font-size: 24px; font-weight: 700; }
            QLabel[badge="true"] {
                color: #7ff5c7;
                background: rgba(30,180,120,0.16);
                border: 1px solid rgba(70,225,160,0.35);
            }
            QFrame[card="true"] {
                background: #2c2c2e;
                border: 1px solid #3a3a3c;
                border-radius: 12px;
            }
            QFrame[sidebarCard="true"] {
                background: rgba(44,44,46,0.88);
                border: 1px solid #3a3a3c;
                border-radius: 11px;
            }
            QListWidget#navigation {
                background: transparent;
                border: none;
                outline: none;
                font-size: 13px;
                color: #d1d1d6;
            }
            QListWidget#navigation::item {
                padding: 10px 12px;
                margin: 2px 0;
                border-radius: 8px;
            }
            QListWidget#navigation::item:hover:!selected {
                background: rgba(255,255,255,0.06);
            }
            QListWidget#navigation::item:selected {
                color: white;
                background: #0a84ff;
                font-weight: 600;
            }
            QPushButton {
                color: #f5f5f7;
                background: #3a3a3c;
                border: 1px solid #48484a;
            }
            QPushButton:hover { background: #48484a; }
            QPushButton[primary="true"] {
                color: white;
                background: #0a84ff;
                border-color: #0a84ff;
            }
            QPushButton[primary="true"]:hover { background: #0070e0; }
            QPushButton[secondary="true"] { background: #333335; }
            QCheckBox { color: #d1d1d6; }
            QCheckBox::indicator {
                border: 1px solid #636366;
                background: #333335;
            }
            QCheckBox::indicator:checked {
                background: #0a84ff;
                border-color: #0a84ff;
            }
            QPlainTextEdit {
                color: #e5e5ea;
                background: #202022;
                border: 1px solid #3a3a3c;
            }
            QProgressBar { background: #3a3a3c; }
            QProgressBar::chunk { background: #0a84ff; }
            QStatusBar {
                color: #98989d;
                background: #1c1c1e;
                border-color: #343438;
            }
            QMessageBox, QMessageBox QLabel {
                background: #2c2c2e;
                color: #f5f5f7;
            }
            QMessageBox QPushButton {
                min-width: 82px;
            }
        )";
    }
};

int main(int argc, char **argv) {
    QApplication app(argc, argv);
    QApplication::setApplicationName("ROM3-j613 Control Center");
    QApplication::setOrganizationName("ROM3-j613");

    MainWindow window;
    window.show();
    return app.exec();
}
