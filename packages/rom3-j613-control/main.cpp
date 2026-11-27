#include <QApplication>
#include <QCheckBox>
#include <QDateTime>
#include <QFile>
#include <QFileInfo>
#include <QFontDatabase>
#include <QFormLayout>
#include <QFrame>
#include <QHBoxLayout>
#include <QLabel>
#include <QMainWindow>
#include <QMessageBox>
#include <QPlainTextEdit>
#include <QProcess>
#include <QProcessEnvironment>
#include <QProgressBar>
#include <QPushButton>
#include <QStatusBar>
#include <QTextCursor>
#include <QVBoxLayout>
#include <QWidget>

class MainWindow final : public QMainWindow {
public:
    MainWindow() {
        setWindowTitle("ROM3 Control Center");
        setMinimumSize(980, 720);
        resize(1040, 780);

        auto *central = new QWidget(this);
        central->setObjectName("root");
        auto *layout = new QVBoxLayout(central);
        layout->setContentsMargins(28, 24, 28, 24);
        layout->setSpacing(16);

        auto *title = new QLabel("ROM3-j613 Control Center", central);
        QFont titleFont = title->font();
        titleFont.setPointSize(titleFont.pointSize() + 9);
        titleFont.setBold(true);
        title->setFont(titleFont);
        layout->addWidget(title);

        auto *subtitle = new QLabel(
            "Tested Apple J613 system stack · updates, diagnostics and recovery",
            central);
        subtitle->setWordWrap(true);
        subtitle->setProperty("muted", true);
        layout->addWidget(subtitle);
        auto *badge = new QLabel("APPLE J613  ·  ROM3 TESTED", central);
        badge->setProperty("badge", true);
        layout->addWidget(badge, 0, Qt::AlignLeft);

        auto *statusFrame = new QFrame(central);
        statusFrame->setProperty("card", true);
        auto *statusForm = new QFormLayout(statusFrame);
        statusForm->setContentsMargins(16, 14, 16, 14);
        statusForm->setHorizontalSpacing(20);
        kernelLabel = new QLabel(statusFrame);
        bootLabel = new QLabel(statusFrame);
        systemFirmwareLabel = new QLabel(statusFrame);
        componentFirmwareLabel = new QLabel(statusFrame);
        packageLabel = new QLabel(statusFrame);
        packageLabel->setWordWrap(true);
        statusForm->addRow("Linux kernel", kernelLabel);
        statusForm->addRow("ROM3 bootloader", bootLabel);
        statusForm->addRow("Apple system firmware", systemFirmwareLabel);
        statusForm->addRow("Apple component firmware", componentFirmwareLabel);
        statusForm->addRow("Protected package set", packageLabel);
        layout->addWidget(statusFrame);

        auto *policy = new QLabel(
            "Safe update mode can upgrade ordinary Arch packages while keeping "
            "the ROM3 kernel, bootloader, GPU, audio and compositor stack pinned.",
            central);
        policy->setWordWrap(true);
        policy->setProperty("hint", true);
        layout->addWidget(policy);

        auto *maintenance = new QFrame(central);
        maintenance->setProperty("card", true);
        auto *maintenanceLayout = new QVBoxLayout(maintenance);
        maintenanceLayout->setContentsMargins(16, 12, 16, 14);
        maintenanceLayout->setSpacing(10);
        auto *maintenanceCaption =
            new QLabel("SYSTEM MAINTENANCE", maintenance);
        maintenanceCaption->setProperty("caption", true);
        maintenanceLayout->addWidget(maintenanceCaption);

        auto *buttons = new QHBoxLayout();
        buttons->setSpacing(10);
        checkButton = new QPushButton("Check safe updates", central);
        applyButton = new QPushButton("Apply safe updates", central);
        githubCheckButton = new QPushButton("Check ROM3 release", central);
        githubApplyButton = new QPushButton("Install ROM3 release", central);
        verifyButton = new QPushButton("Verify system", central);
        auto *refreshButton = new QPushButton("Refresh status", central);
        checkButton->setProperty("secondary", true);
        applyButton->setProperty("primary", true);
        githubCheckButton->setProperty("secondary", true);
        githubApplyButton->setProperty("primary", true);
        verifyButton->setProperty("secondary", true);
        refreshButton->setProperty("secondary", true);
        buttons->addWidget(checkButton);
        buttons->addWidget(applyButton);
        buttons->addWidget(verifyButton);
        buttons->addStretch();
        buttons->addWidget(refreshButton);
        maintenanceLayout->addLayout(buttons);
        layout->addWidget(maintenance);

        auto *github = new QFrame(central);
        github->setProperty("card", true);
        auto *githubLayout = new QVBoxLayout(github);
        githubLayout->setContentsMargins(16, 12, 16, 14);
        githubLayout->setSpacing(10);
        auto *githubCaption =
            new QLabel("SIGNED ROM3 RELEASES FROM GITHUB", github);
        githubCaption->setProperty("caption", true);
        githubLayout->addWidget(githubCaption);
        auto *githubButtons = new QHBoxLayout();
        githubButtons->setSpacing(10);
        githubButtons->addWidget(githubCheckButton);
        githubButtons->addWidget(githubApplyButton);
        githubButtons->addStretch();
        githubLayout->addLayout(githubButtons);
        layout->addWidget(github);

        auto *automation = new QFrame(central);
        automation->setProperty("card", true);
        auto *automatic = new QHBoxLayout(automation);
        automatic->setContentsMargins(16, 10, 16, 10);
        automatic->setSpacing(10);
        autoCheck = new QCheckBox(
            "Install new signed ROM3 releases automatically", central);
        saveAutoButton = new QPushButton("Save automation", central);
        saveAutoButton->setProperty("secondary", true);
        automatic->addWidget(autoCheck);
        automatic->addStretch();
        automatic->addWidget(saveAutoButton);
        layout->addWidget(automation);

        progress = new QProgressBar(central);
        progress->setRange(0, 1);
        progress->setValue(0);
        progress->setTextVisible(false);
        layout->addWidget(progress);

        auto *outputCard = new QFrame(central);
        outputCard->setProperty("card", true);
        auto *outputLayout = new QVBoxLayout(outputCard);
        outputLayout->setContentsMargins(12, 10, 12, 12);
        outputLayout->setSpacing(8);
        auto *outputCaption = new QLabel("ACTIVITY LOG", outputCard);
        outputCaption->setProperty("caption", true);
        outputLayout->addWidget(outputCaption);
        output = new QPlainTextEdit(outputCard);
        output->setReadOnly(true);
        output->setFont(QFontDatabase::systemFont(QFontDatabase::FixedFont));
        output->setPlaceholderText(
            "Update and verification output appears here.");
        outputLayout->addWidget(output, 1);
        layout->addWidget(outputCard, 1);

        setStyleSheet(R"(
            QWidget#root {
                background: qlineargradient(
                    x1: 0, y1: 0, x2: 1, y2: 1,
                    stop: 0 #07111e, stop: 0.55 #0b1c2d, stop: 1 #122d43);
                color: #edf6ff;
                font-family: "Noto Sans", "Noto Sans Display", sans-serif;
            }
            QLabel { color: #edf6ff; }
            QLabel[muted="true"] { color: #8da8c2; font-size: 12px; }
            QLabel[caption="true"] {
                color: #7fa5c5;
                font-size: 10px;
                font-weight: 700;
                letter-spacing: 1px;
            }
            QLabel[hint="true"] { color: #9bb7cf; }
            QLabel[badge="true"] {
                color: #6ff3e4;
                background: rgba(25, 174, 166, 0.15);
                border: 1px solid rgba(74, 226, 210, 0.45);
                border-radius: 11px;
                padding: 6px 12px;
                font-size: 10px;
                font-weight: 700;
            }
            QFrame[card="true"] {
                background: rgba(13, 25, 39, 0.88);
                border: 1px solid rgba(116, 160, 194, 0.22);
                border-radius: 14px;
            }
            QPushButton {
                background: #1a334a;
                color: #eaf6ff;
                border: 1px solid rgba(133, 183, 219, 0.30);
                border-radius: 9px;
                padding: 9px 15px;
                font-weight: 600;
            }
            QPushButton:hover {
                background: #234562;
                border-color: rgba(93, 225, 219, 0.70);
            }
            QPushButton:pressed { background: #102638; }
            QPushButton:disabled {
                color: #647c91;
                background: #142434;
            }
            QPushButton[primary="true"] {
                color: #04191e;
                background: #36e5d0;
                border-color: #7ff8eb;
            }
            QPushButton[primary="true"]:hover { background: #66f1e1; }
            QPushButton[secondary="true"] {
                background: rgba(28, 55, 77, 0.82);
            }
            QCheckBox { color: #d9e9f7; spacing: 9px; }
            QCheckBox::indicator {
                width: 17px;
                height: 17px;
                border-radius: 5px;
                border: 1px solid #6485a0;
                background: #102235;
            }
            QCheckBox::indicator:checked {
                background: #36e5d0;
                border-color: #8affef;
            }
            QPlainTextEdit {
                color: #cfe7f5;
                background: rgba(5, 14, 24, 0.92);
                border: 1px solid rgba(103, 151, 183, 0.20);
                border-radius: 9px;
                padding: 9px;
                selection-background-color: #187f88;
            }
            QProgressBar {
                min-height: 5px;
                max-height: 5px;
                background: #10263a;
                border: none;
                border-radius: 2px;
            }
            QProgressBar::chunk {
                background: #36e5d0;
                border-radius: 2px;
            }
            QStatusBar {
                color: #95b2c9;
                background: #081521;
                border-top: 1px solid rgba(106, 151, 184, 0.20);
            }
        )");

        setCentralWidget(central);
        statusBar()->showMessage("Ready");

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
                "override from GitHub?",
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
            output->appendPlainText(
                QString("\n[%1] %2 (exit %3)")
                    .arg(QDateTime::currentDateTime().toString("HH:mm:ss"),
                         success ? "Finished" : "Failed")
                    .arg(exitCode));
            statusBar()->showMessage(success ? "Operation completed"
                                             : "Operation failed");
            refreshStatus();
        });
        connect(&process, &QProcess::errorOccurred, this,
                [this](QProcess::ProcessError error) {
            if (error == QProcess::FailedToStart) {
                appendProcessOutput();
                setBusy(false);
                output->appendPlainText(
                    "\nCould not start the requested operation.");
            }
        });

        refreshStatus();
    }

private:
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
    QCheckBox *autoCheck{};
    QPushButton *saveAutoButton{};
    QProgressBar *progress{};
    QPlainTextEdit *output{};
    QProcess process;

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
            return "unavailable";
        if (command.exitStatus() != QProcess::NormalExit ||
            command.exitCode() != 0)
            return "unavailable";
        return QString::fromUtf8(command.readAll()).trimmed();
    }

    void refreshStatus() {
        kernelLabel->setText(
            readProperty("/proc/sys/kernel/osrelease"));
        bootLabel->setText(readProperty(
            "/sys/firmware/devicetree/base/chosen/"
            "asahi,m1n1-stage2-version"));
        systemFirmwareLabel->setText(readProperty(
            "/sys/firmware/devicetree/base/chosen/"
            "asahi,system-fw-version"));
        componentFirmwareLabel->setText(readProperty(
            "/sys/firmware/devicetree/base/chosen/"
            "asahi,os-fw-version"));

        const QString packages = commandOutput(
            "/usr/bin/pacman",
            {"-Q", "linux-rom3", "rom3", "mesa-rom3",
             "pipewire", "kwin", "rom3-j613-meta"});
        packageLabel->setText(packages.isEmpty() ? "unavailable" : packages);

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
        const QString text =
            QString::fromLocal8Bit(process.readAll());
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
        autoCheck->setEnabled(!busy);
        saveAutoButton->setEnabled(!busy);
        progress->setRange(0, busy ? 0 : 1);
        progress->setValue(busy ? 0 : 1);
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
