import UIKit
import ARKit
import SceneKit
import Photos

class ARPhotoViewController: UIViewController {
    
    @IBOutlet var sceneView: ARSCNView!
    
    private var photoNodes: [SCNNode] = []
    private var savedPhotoData: [PhotoData] = []
    private var selectedNodeForManipulation: SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupARScene()
        setupUI()
        loadSavedPhotos()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    private func setupARScene() {
        sceneView.delegate = self
        sceneView.showsStatistics = false
        sceneView.debugOptions = []
        
        // 添加手势识别
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.5
        sceneView.addGestureRecognizer(longPressGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        sceneView.addGestureRecognizer(pinchGesture)
        
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        sceneView.addGestureRecognizer(rotationGesture)
    }
    
    private func setupUI() {
        // 返回按钮
        let backButton = UIButton(type: .system)
        backButton.setTitle("← 返回", for: .normal)
        backButton.backgroundColor = UIColor.systemGray5
        backButton.setTitleColor(.label, for: .normal)
        backButton.layer.cornerRadius = 20
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        
        // 添加照片按钮
        let addPhotoButton = UIButton(type: .system)
        addPhotoButton.setTitle("📷 添加照片", for: .normal)
        addPhotoButton.backgroundColor = UIColor.systemBlue
        addPhotoButton.setTitleColor(.white, for: .normal)
        addPhotoButton.layer.cornerRadius = 25
        addPhotoButton.translatesAutoresizingMaskIntoConstraints = false
        addPhotoButton.addTarget(self, action: #selector(addPhotoTapped), for: .touchUpInside)
        
        // 保存按钮
        let saveButton = UIButton(type: .system)
        saveButton.setTitle("💾", for: .normal)
        saveButton.backgroundColor = UIColor.systemGreen
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 25
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(savePhotoPositions), for: .touchUpInside)
        
        // 清除按钮
        let clearButton = UIButton(type: .system)
        clearButton.setTitle("🗑️", for: .normal)
        clearButton.backgroundColor = UIColor.systemRed
        clearButton.setTitleColor(.white, for: .normal)
        clearButton.layer.cornerRadius = 25
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.addTarget(self, action: #selector(clearAllPhotos), for: .touchUpInside)
        
        // 帮助标签
        let helpLabel = UILabel()
        helpLabel.text = "点击屏幕放置照片 • 点击照片删除 • 长按移动"
        helpLabel.font = UIFont.systemFont(ofSize: 12)
        helpLabel.textColor = UIColor.white
        helpLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        helpLabel.textAlignment = .center
        helpLabel.layer.cornerRadius = 15
        helpLabel.layer.masksToBounds = true
        helpLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(backButton)
        view.addSubview(addPhotoButton)
        view.addSubview(saveButton)
        view.addSubview(clearButton)
        view.addSubview(helpLabel)
        
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 80),
            backButton.heightAnchor.constraint(equalToConstant: 40),
            
            helpLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            helpLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            helpLabel.heightAnchor.constraint(equalToConstant: 30),
            helpLabel.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: 10),
            helpLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            
            addPhotoButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            addPhotoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addPhotoButton.widthAnchor.constraint(equalToConstant: 120),
            addPhotoButton.heightAnchor.constraint(equalToConstant: 50),
            
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            saveButton.widthAnchor.constraint(equalToConstant: 50),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            
            clearButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            clearButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            clearButton.widthAnchor.constraint(equalToConstant: 50),
            clearButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func backTapped() {
        dismiss(animated: true)
    }
    
    @objc private func addPhotoTapped() {
        presentImagePicker()
    }
    
    @objc private func savePhotoPositions() {
        saveCurrentPhotoPositions()
        showAlert(title: "保存成功", message: "照片位置已保存")
    }
    
    @objc private func clearAllPhotos() {
        let alert = UIAlertController(title: "确认清除", message: "确定要清除所有照片吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .destructive) { _ in
            self.photoNodes.forEach { $0.removeFromParentNode() }
            self.photoNodes.removeAll()
            self.savedPhotoData.removeAll()
            UserDefaults.standard.removeObject(forKey: "SavedPhotoData")
            self.showAlert(title: "清除完成", message: "所有照片已清除")
        })
        present(alert, animated: true)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: sceneView)
        
        // 检查是否点击了照片节点
        let hitResults = sceneView.hitTest(location, options: nil)
        if let hitNode = hitResults.first?.node, photoNodes.contains(hitNode) {
            
            // 如果已经选中了这个节点，则删除它
            if selectedNodeForManipulation == hitNode {
                let alert = UIAlertController(title: "删除照片", message: "确定要删除这张照片吗？", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "取消", style: .cancel))
                alert.addAction(UIAlertAction(title: "删除", style: .destructive) { _ in
                    self.highlightNode(hitNode, highlight: false)
                    hitNode.removeFromParentNode()
                    if let index = self.photoNodes.firstIndex(of: hitNode) {
                        self.photoNodes.remove(at: index)
                    }
                    self.selectedNodeForManipulation = nil
                })
                present(alert, animated: true)
                return
            }
            
            // 取消之前选中的节点
            if let previousSelected = selectedNodeForManipulation {
                highlightNode(previousSelected, highlight: false)
            }
            
            // 选中新节点
            selectedNodeForManipulation = hitNode
            highlightNode(hitNode, highlight: true)
            return
        }
        
        // 如果点击了空白区域，取消选择
        if let selectedNode = selectedNodeForManipulation {
            highlightNode(selectedNode, highlight: false)
            selectedNodeForManipulation = nil
        }
        
        // 如果没有选中的照片，不执行摆放操作
        guard let selectedImage = selectedImageForPlacement else { return }
        
        // 在点击位置放置照片
        let arHitResults = sceneView.hitTest(location, types: [.existingPlaneUsingExtent, .estimatedHorizontalPlane])
        if let hitResult = arHitResults.first {
            placePhoto(selectedImage, at: hitResult)
            selectedImageForPlacement = nil
        }
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        
        let location = gesture.location(in: sceneView)
        let hitResults = sceneView.hitTest(location, options: nil)
        
        if let hitNode = hitResults.first?.node, photoNodes.contains(hitNode) {
            // 长按移动照片
            selectedNodeForManipulation = hitNode
            highlightNode(hitNode, highlight: true)
        }
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let selectedNode = selectedNodeForManipulation else { return }
        
        switch gesture.state {
        case .changed:
            let scale = Float(gesture.scale)
            selectedNode.scale = SCNVector3(scale, scale, scale)
        case .ended:
            gesture.scale = 1.0
        default:
            break
        }
    }
    
    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let selectedNode = selectedNodeForManipulation else { return }
        
        switch gesture.state {
        case .changed:
            selectedNode.eulerAngles.y = Float(gesture.rotation)
        case .ended:
            gesture.rotation = 0
        default:
            break
        }
    }
    
    private var selectedImageForPlacement: UIImage?
    
    private func presentImagePicker() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.allowsEditing = false
        present(imagePickerController, animated: true)
    }
    
    private func placePhoto(_ image: UIImage, at hitResult: ARHitTestResult) {
        let photoNode = createPhotoNode(with: image)
        
        let transform = hitResult.worldTransform
        let position = SCNVector3(transform.columns.3.x, transform.columns.3.y + 0.1, transform.columns.3.z)
        photoNode.position = position
        
        sceneView.scene.rootNode.addChildNode(photoNode)
        photoNodes.append(photoNode)
    }
    
    private func createPhotoNode(with image: UIImage) -> SCNNode {
        // 计算照片的宽高比
        let aspectRatio = image.size.width / image.size.height
        let baseSize: Float = 0.25
        let width = aspectRatio > 1 ? baseSize : baseSize * Float(aspectRatio)
        let height = aspectRatio > 1 ? baseSize / Float(aspectRatio) : baseSize
        
        let plane = SCNPlane(width: CGFloat(width), height: CGFloat(height))
        plane.firstMaterial?.diffuse.contents = image
        plane.firstMaterial?.isDoubleSided = true
        
        // 添加阴影效果
        plane.firstMaterial?.multiply.contents = UIColor.white
        plane.firstMaterial?.lightingModel = .lambert
        
        let node = SCNNode(geometry: plane)
        
        // 添加白色边框
        let borderWidth = width + 0.02
        let borderHeight = height + 0.02
        let borderPlane = SCNPlane(width: CGFloat(borderWidth), height: CGFloat(borderHeight))
        borderPlane.firstMaterial?.diffuse.contents = UIColor.white
        let borderNode = SCNNode(geometry: borderPlane)
        borderNode.position = SCNVector3(0, 0, -0.001)
        borderNode.name = "border"
        node.addChildNode(borderNode)
        
        // 添加阴影
        let shadowPlane = SCNPlane(width: CGFloat(borderWidth + 0.01), height: CGFloat(borderHeight + 0.01))
        shadowPlane.firstMaterial?.diffuse.contents = UIColor.black.withAlphaComponent(0.3)
        let shadowNode = SCNNode(geometry: shadowPlane)
        shadowNode.position = SCNVector3(0.005, -0.005, -0.002)
        shadowNode.name = "shadow"
        node.addChildNode(shadowNode)
        
        return node
    }
    
    private func highlightNode(_ node: SCNNode, highlight: Bool) {
        if let borderNode = node.childNode(withName: "border", recursively: false) {
            let material = borderNode.geometry?.firstMaterial
            if highlight {
                material?.diffuse.contents = UIColor.systemBlue
                material?.emission.contents = UIColor.systemBlue.withAlphaComponent(0.3)
            } else {
                material?.diffuse.contents = UIColor.white
                material?.emission.contents = UIColor.clear
            }
        }
    }
    
    private func movePhoto(_ node: SCNNode, gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: sceneView)
        let arHitResults = sceneView.hitTest(location, types: [.existingPlaneUsingExtent, .estimatedHorizontalPlane])
        
        if let hitResult = arHitResults.first {
            let transform = hitResult.worldTransform
            let newPosition = SCNVector3(transform.columns.3.x, transform.columns.3.y + 0.1, transform.columns.3.z)
            
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.3
            node.position = newPosition
            SCNTransaction.commit()
        }
    }
    
    private func saveCurrentPhotoPositions() {
        savedPhotoData.removeAll()
        
        for node in photoNodes {
            if let material = node.geometry?.firstMaterial,
               let image = material.diffuse.contents as? UIImage,
               let imageData = image.jpegData(compressionQuality: 0.8) {
                
                let photoData = PhotoData(
                    imageData: imageData,
                    position: [node.position.x, node.position.y, node.position.z],
                    rotation: [node.eulerAngles.x, node.eulerAngles.y, node.eulerAngles.z],
                    scale: [node.scale.x, node.scale.y, node.scale.z]
                )
                savedPhotoData.append(photoData)
            }
        }
        
        if let encoded = try? JSONEncoder().encode(savedPhotoData) {
            UserDefaults.standard.set(encoded, forKey: "SavedPhotoData")
        }
    }
    
    private func loadSavedPhotos() {
        guard let data = UserDefaults.standard.data(forKey: "SavedPhotoData"),
              let decoded = try? JSONDecoder().decode([PhotoData].self, from: data) else {
            return
        }
        
        savedPhotoData = decoded
        
        // 延迟加载，等待AR会话初始化
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.restoreSavedPhotos()
        }
    }
    
    private func restoreSavedPhotos() {
        for photoData in savedPhotoData {
            if let image = UIImage(data: photoData.imageData) {
                let photoNode = createPhotoNode(with: image)
                photoNode.position = SCNVector3(photoData.position[0], photoData.position[1], photoData.position[2])
                photoNode.eulerAngles = SCNVector3(photoData.rotation[0], photoData.rotation[1], photoData.rotation[2])
                
                // 恢复缩放信息（如果存在）
                if photoData.scale.count >= 3 {
                    photoNode.scale = SCNVector3(photoData.scale[0], photoData.scale[1], photoData.scale[2])
                }
                
                sceneView.scene.rootNode.addChildNode(photoNode)
                photoNodes.append(photoNode)
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - ARSCNViewDelegate
extension ARPhotoViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // 可以在这里添加平面检测的可视化
    }
}

// MARK: - UIImagePickerControllerDelegate
extension ARPhotoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[.originalImage] as? UIImage {
            selectedImageForPlacement = image
            showAlert(title: "照片已选择", message: "点击屏幕任意位置放置照片")
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - PhotoData Model
struct PhotoData: Codable {
    let imageData: Data
    let position: [Float]
    let rotation: [Float]
    let scale: [Float]
    
    // 为了向后兼容，提供默认的scale值
    init(imageData: Data, position: [Float], rotation: [Float], scale: [Float] = [1.0, 1.0, 1.0]) {
        self.imageData = imageData
        self.position = position
        self.rotation = rotation
        self.scale = scale
    }
}