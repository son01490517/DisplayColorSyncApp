//
//  ViewController.swift
//  DisplayColorSyncApp
//
//  Created by SCN on 15/04/2025.
//

import Cocoa

class ViewController: NSViewController {

    weak var appDelegate: AppDelegate?

    private let statusLabel: NSTextField = {
        let label = NSTextField(labelWithString: "DisplayColorSyncApp is running.")
        label.font = NSFont.systemFont(ofSize: 14)
        label.alignment = .center
        return label
    }()

    private let applyButton: NSButton = {
        let button = NSButton(title: "Apply ICC now", target: nil, action: nil)
        button.bezelStyle = .rounded
        return button
    }()
    
    private let autoApplyButton: NSButton = {
        let button = NSButton(title: "Pause ICC auto apply", target: nil, action: nil)
        button.bezelStyle = .rounded
        button.controlSize = .regular
        return button
    }()
    
    private let resetButton: NSButton = {
        let button = NSButton(title: "Reset ICC to default settings", target: nil, action: nil)
        button.bezelStyle = .rounded
        button.controlSize = .regular
        return button
    }()

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 480, height: 320))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }

    private func setupUI() {
        applyButton.target = self
        applyButton.action = #selector(applyNow)
        
        autoApplyButton.target = self
        autoApplyButton.action = #selector(toggleAutoApply)
        
        resetButton.target = self
        resetButton.action = #selector(resetToDefault)
        
        // Update initial button state
        if let appDelegate = appDelegate {
            updateAutoApplyStatus(appDelegate.isAutoApplyEnabled)
        }

        let stackView = NSStackView(views: [statusLabel, applyButton, autoApplyButton, resetButton])
        stackView.orientation = .vertical
        stackView.alignment = .centerX
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    func updateAutoApplyStatus(_ enabled: Bool) {
        DispatchQueue.main.async {
            if enabled {
                self.autoApplyButton.title = "Pause ICC auto apply"
                self.statusLabel.stringValue = "ICC auto apply: ON"
            } else {
                self.autoApplyButton.title = "Resume ICC auto apply"
                self.statusLabel.stringValue = "ICC auto apply: OFF"
            }
        }
    }

    @objc private func applyNow() {
        appDelegate?.handleDisplayChange()
    }
    
    @objc private func toggleAutoApply() {
        appDelegate?.toggleAutoApply()
    }
    
    @objc private func resetToDefault() {
        appDelegate?.resetGammaToDefault()
    }
}

