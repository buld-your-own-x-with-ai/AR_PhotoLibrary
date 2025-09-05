import UIKit
import ARKit
import Photos

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        checkPermissions()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        // 标题
        let titleLabel = UILabel()
        titleLabel.text = "AR 照片摆放"
        titleLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 描述
        let descriptionLabel = UILabel()
        descriptionLabel.text = "将相册中的照片摆放到现实世界中\n支持保存和自动恢复位置"
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textColor = UIColor.secondaryLabel
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 开始按钮
        let startButton = UIButton(type: .system)
        startButton.setTitle("开始体验", for: .normal)
        startButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        startButton.backgroundColor = UIColor.systemBlue
        startButton.setTitleColor(.white, for: .normal)
        startButton.layer.cornerRadius = 25
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.addTarget(self, action: #selector(startARExperience), for: .touchUpInside)
        
        // 权限状态标签
        let permissionLabel = UILabel()
        permissionLabel.text = "检查权限中..."
        permissionLabel.font = UIFont.systemFont(ofSize: 14)
        permissionLabel.textAlignment = .center
        permissionLabel.textColor = UIColor.secondaryLabel
        permissionLabel.translatesAutoresizingMaskIntoConstraints = false
        permissionLabel.tag = 100 // 用于后续更新
        
        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(startButton)
        view.addSubview(permissionLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            
            descriptionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 60),
            startButton.widthAnchor.constraint(equalToConstant: 200),
            startButton.heightAnchor.constraint(equalToConstant: 50),
            
            permissionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            permissionLabel.topAnchor.constraint(equalTo: startButton.bottomAnchor, constant: 30),
            permissionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            permissionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }
    
    private func checkPermissions() {
        let permissionLabel = view.viewWithTag(100) as? UILabel
        
        // 检查AR支持
        guard ARWorldTrackingConfiguration.isSupported else {
            permissionLabel?.text = "❌ 设备不支持ARKit"
            permissionLabel?.textColor = UIColor.systemRed
            return
        }
        
        // 检查相机权限
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let photoStatus = PHPhotoLibrary.authorizationStatus()
        
        if cameraStatus == .authorized && (photoStatus == .authorized || photoStatus == .limited) {
            permissionLabel?.text = "✅ 权限已获取，可以开始体验"
            permissionLabel?.textColor = UIColor.systemGreen
        } else {
            permissionLabel?.text = "⚠️ 需要相机和相册权限"
            permissionLabel?.textColor = UIColor.systemOrange
            requestPermissions()
        }
    }
    
    private func requestPermissions() {
        // 请求相机权限
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.requestPhotoLibraryPermission()
                } else {
                    self?.showPermissionAlert(for: "相机")
                }
            }
        }
    }
    
    private func requestPhotoLibraryPermission() {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.updatePermissionStatus()
            }
        }
    }
    
    private func updatePermissionStatus() {
        let permissionLabel = view.viewWithTag(100) as? UILabel
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let photoStatus = PHPhotoLibrary.authorizationStatus()
        
        if cameraStatus == .authorized && (photoStatus == .authorized || photoStatus == .limited) {
            permissionLabel?.text = "✅ 权限已获取，可以开始体验"
            permissionLabel?.textColor = UIColor.systemGreen
        } else {
            permissionLabel?.text = "❌ 权限不足，请在设置中开启"
            permissionLabel?.textColor = UIColor.systemRed
        }
    }
    
    private func showPermissionAlert(for permission: String) {
        let alert = UIAlertController(
            title: "需要\(permission)权限",
            message: "请在设置中开启\(permission)权限以使用AR功能",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "去设置", style: .default) { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc private func startARExperience() {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let photoStatus = PHPhotoLibrary.authorizationStatus()
        
        guard cameraStatus == .authorized && (photoStatus == .authorized || photoStatus == .limited) else {
            showPermissionAlert(for: "相机和相册")
            return
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let arViewController = storyboard.instantiateViewController(withIdentifier: "ARPhotoViewController") as? ARPhotoViewController {
            arViewController.modalPresentationStyle = .fullScreen
            present(arViewController, animated: true)
        }
    }
}