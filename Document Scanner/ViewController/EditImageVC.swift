//
//  EditImageVC.swift
//  Document Scanner
//
//  Created by Sandesh on 08/03/21.
//

import UIKit
import WeScan

protocol EditImageVCDelegate: class {
    func cancelImageEditing(_controller: EditImageVC)
    func rescanImageEditing(_ controller: EditImageVC)
    func finishedImageEditing(_ finalImage: UIImage, originalImage: UIImage, controller: EditImageVC)
}

class EditImageVC: UIViewController {
    
    enum ImageEditingMode {
        case basic
        case correction
        case filtering
    }

    private var editVC: EditImageViewController!
    
    var imageEditingMode: ImageEditingMode? {
        didSet {
            if editVC != nil {
                _updateViewForEditing()
            }
        }
    }
    
    //set externally
    var quad: Quadrilateral?
    var imageToEdit: UIImage? //original image
    weak var delegate: EditImageVCDelegate?
    
    //temporary images
    private var _croppedImage: UIImage? //cropped image for filtering
    private var _editedImage: UIImage?
    
    private var imageView: UIImageView?
    
    // MARK: - IBoutlets
    @IBOutlet weak var imageEditorView: UIView!
    @IBOutlet weak var footerView: UIView!
    
    //button left to right in xib
    @IBOutlet weak var editButtonOneContainer: UIView!
    @IBOutlet weak var editButtonOne: UIButton!
    @IBOutlet weak var editButtonTwoContainer: UIView!
    @IBOutlet weak var editButtonTwo: UIButton!
    @IBOutlet weak var editButtonThreeContainer: UIView!
    @IBOutlet weak var editButtonThree:UIButton!
    @IBOutlet weak var editButtonFourContainer: UIView!
    @IBOutlet weak var editButtonFour: UIButton!
    @IBOutlet weak var editButtonFiveContainer: UIView!
    @IBOutlet weak var editButtonFive: UIButton!

    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    private func setupViews() {
        //one time view setups
        guard let imageToEdit = imageToEdit , let quad = quad else {
            fatalError("ERROR: No image or quad is set for editing")
        }
        
        editVC = WeScan.EditImageViewController(image: imageToEdit, quad: quad, strokeColor: UIColor(red: (69.0 / 255.0), green: (194.0 / 255.0), blue: (177.0 / 255.0), alpha: 1.0).cgColor)
        editVC.view.frame = imageEditorView.bounds
        editVC.willMove(toParent: self)
        imageEditorView.addSubview(editVC.view)
        self.addChild(editVC)
        editVC.didMove(toParent: self)
        editVC.delegate = self
        
        //recurring view setups
        _updateViewForEditing()
    }
    
    private func _updateViewForEditing() {
        guard let editingMode = imageEditingMode else {
            fatalError("ERROR: Image editing mode not set")
        }
        switch  editingMode {
        case .basic: _setupEditorViewForBasicEditingMode()
        case .correction : _setupEditorViewForCorrectionMode()
        case .filtering : _setupEditorViewForFilteringMode()
        }
    }
    
    private func _setupEditorViewForBasicEditingMode() {
        editButtonOneContainer.isHidden = false
        editButtonTwoContainer.isHidden = false
        editButtonThreeContainer.isHidden = true
        editButtonFourContainer.isHidden = false
        editButtonFiveContainer.isHidden = true
        
        editButtonOne.setImage(Icons.cancel, for: .normal)
        editButtonTwo.setImage(Icons.camera, for: .normal)
        editButtonFour.setImage(Icons.crop, for: .normal)
    }
    
    private func _setupEditorViewForCorrectionMode() {
        editButtonOneContainer.isHidden = false
        editButtonTwoContainer.isHidden = false
        editButtonThreeContainer.isHidden = false
        editButtonFourContainer.isHidden = false
        editButtonFiveContainer.isHidden = false
        
        editButtonOne.setImage(Icons.cancel, for: .normal)
        editButtonTwo.setImage(Icons.flash, for: .normal)
        editButtonThree.setImage(Icons.reset, for: .normal)
        editButtonFour.setImage(Icons.rotateLeft, for: .normal)
        editButtonFive.setImage(Icons.done, for: .normal)
    }
    
    private func _setupEditorViewForFilteringMode() {
        
    }
    
    
    
    //cancel editing
    @IBAction func didTapEditButtonOne(_ sender: UIButton) {
        delegate?.cancelImageEditing(_controller: self)
    }
    
    // rescan image
    @IBAction func didTapEditButtonTwo(_ sender: UIButton) {
        guard let editingMode = imageEditingMode else {
            fatalError("ERROR: Image editing mode not set")
        }
        
        switch editingMode {
        case .basic:
            delegate?.rescanImageEditing(self)
        case .correction:
            delegate?.rescanImageEditing(self)
        case .filtering:
            break
        }
    }
    
    //
    @IBAction func didTapEditButtonThree(_ sender: UIButton) {
        guard let editingMode = imageEditingMode else {
            fatalError("ERROR: Image editing mode not set")
        }
        
        switch editingMode {
        case .basic:
            break
        case .correction:
            break
        case .filtering:
            break
        }
    }
    
    @IBAction func didTapEditButtonFour(_ sender: UIButton) {
        guard let editingMode = imageEditingMode else {
            fatalError("ERROR: Image editing mode not set")
        }
        
        switch editingMode {
        case .basic:
            editVC.cropImage()
        case .correction:
            break
        case .filtering:
            break
        }
    }
    
    @IBAction func didTapEditButtonFive(_ sender: Any) {
        guard let editingMode = imageEditingMode else {
            fatalError("ERROR: Image editing mode not set")
        }
        
        switch editingMode {
        case .basic:
            break
        case .correction:
            break
        case .filtering:
            break
        }
    }
    
    
}

extension EditImageVC: EditImageViewDelegate {
    func cropped(image: UIImage) {
        _croppedImage = image
        imageView = UIImageView()
        imageView?.image = image
        imageView?.frame = imageEditorView.bounds
        imageEditorView.addSubview(imageView!)
        imageEditorView.bringSubviewToFront(imageView!)
        imageView?.contentMode = .scaleAspectFit
        editVC.view.removeFromSuperview()
        imageEditingMode = .correction
    }
}
