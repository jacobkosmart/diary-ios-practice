//
//  WriteDiaryViewController.swift
//  04_Diary
//
//  Created by Jacob Ko on 2021/12/15.
//

import UIKit

// detail page 에서 넘겨 editBtn 을 통해 넘어온 데이터 처리
enum DiaryEditorMode {
	case new
	case edit(IndexPath, Diary)
}


protocol WriteDiaryViewDelegate: AnyObject {
	func didSelectReigster(diary: Diary)
}

class WriteDiaryViewController: UIViewController {
	@IBOutlet weak var contentsTextView: UITextView!
	@IBOutlet weak var titleTextField: UITextField!
	@IBOutlet weak var dateTextField: UITextField!
	@IBOutlet weak var confirmButton: UIBarButtonItem!
	
	// variable
	private let datePicker = UIDatePicker()
	private var diaryDate: Date?
	weak var delegate: WriteDiaryViewDelegate?
	var diaryEditorMode: DiaryEditorMode = .new
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.configureContentsTextView()
		self.configureDatePicker()
		self.configureinputField()
		self.configureEditMode()
		// Add 버튼을 초기 상태에 비활성화 시킴
		self.confirmButton.isEnabled = false
	}
	
	// editMode 일때의 method
	private func configureEditMode() {
		switch self.diaryEditorMode {
			case let .edit(_, diary):
				self.titleTextField.text = diary.title
				self.contentsTextView.text = diary.contents
				self.dateTextField.text = self.dateToString(date: diary.date)
				self.diaryDate = diary.date
				self.confirmButton.title = "Edit"
			
			default:
				break
		}
	}
	
	// Date type 을 String 으로 바꾸는 method
	private func dateToString(date: Date) -> String {
		let formatter = DateFormatter()
		formatter.dateFormat = "yy년 MM월 dd일(EEEEE)"
		formatter.locale = Locale(identifier: "ko_KR")
		return formatter.string(from: date)
	}
	
	// TextViewFiled 의 border color
	private func configureContentsTextView() {
		let borderColor = UIColor(red: 220/255, green: 220/250, blue: 220/255, alpha: 1.0)
		self.contentsTextView.layer.borderColor = borderColor.cgColor
		self.contentsTextView.layer.borderWidth = 0.5
		self.contentsTextView.layer.cornerRadius = 5.0
	}
	
	// datePicker method
	private func configureDatePicker() {
		self.datePicker.datePickerMode = .date
		self.datePicker.preferredDatePickerStyle = .wheels
		self.datePicker.addTarget(self, action: #selector(datePickerValueDidChange(_:)), for: .valueChanged)
		self.datePicker.locale = Locale(identifier: "ko-KR")
		self.dateTextField.inputView = self.datePicker
	}
	
	// 모든 inputmethod 가 작성이 되었을때 Add 버튼을 활성화 시키는 method
	private func configureinputField() {
		self.contentsTextView.delegate = self
		self.titleTextField.addTarget(self, action: #selector(titleTextFieldDidChage(_:)), for: .editingChanged)
		self.dateTextField.addTarget(self, action: #selector(dateTextFieldDidChange(_:)), for: .editingChanged)
	}
	
	// add 버튼 누르면 입력한값 저장하기
	@IBAction func tabConfimButton(_ sender: UIBarButtonItem) {
		guard let title = self.titleTextField.text else { return }
		guard let contents = self.contentsTextView.text else { return }
		guard let date = self.diaryDate else { return }

		
		// .edit 일 경우에만 NotificationCenter post event 발생
		switch self.diaryEditorMode {
		case .new:
			let diary = Diary(
				uuidString: UUID().uuidString,
				title: title,
				contents: contents,
				date: date,
				isHeart: false)
			self.delegate?.didSelectReigster(diary: diary)
			
		case let .edit(indexPath, diary):
			let diary = Diary(
				uuidString: diary.uuidString,
				title: title,
				contents: contents,
				date: date,
				isHeart: diary.isHeart)
			NotificationCenter.default.post(
				name: NSNotification.Name("editDiary"),
				object: diary,
				userInfo: nil
			)
				// 더이상 userInfo 에 indexPath.row 값을 넘겨주지 않아도 됨 uuid 사용
				// userInfo: ["indexPath.row" : indexPath.row])
		}
		
		self.navigationController?.popViewController(animated: true)
	}
	
	// datePicker selector
	@objc private func datePickerValueDidChange(_ datePicker: UIDatePicker) {
		let formater = DateFormatter()
		formater.dateFormat = "yyyy년 MM월 dd일(EEEEE)"
		formater.locale = Locale(identifier: "ko_KR")
		self.diaryDate = datePicker.date
		self.dateTextField.text = formater.string(from: datePicker.date)
		// 날짜가 변경될때 마다 changed actions 를 발생시킴
		self.dateTextField.sendActions(for: .editingChanged)
	}
	
	// title text가 입력될때마다 selector 가 호출 될 수 있게 하는 selector
	@objc private func titleTextFieldDidChage(_ textField: UITextField){
		self.validateInputField()
	}
	
	// date text가 입력될때마다 selector 가 호출 될 수 있게 하는 selector
	@objc private func dateTextFieldDidChange(_ textField: UITextField) {
		self.validateInputField()
	}
	
	
	// 유저가 화면을 터치하면 실행되는 method 로 화면을 터치하면 endEditing 키보드가 닫히게 되는 method
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		self.view.endEditing(true)
	}
	
	// Add버튼의 활성화 여부를 판단하는 method : title, date, contents textField 가 비어있지 않은경우에 confirmbutton 이 enable 하게 만듬
	private func  validateInputField(){
		self.confirmButton.isEnabled = !(self.titleTextField.text?.isEmpty ?? true) && !(self.dateTextField.text?.isEmpty ?? true) && !self.contentsTextView.text.isEmpty
	}
}

// delegate 채택
extension WriteDiaryViewController: UITextViewDelegate {
	// textField 에 text 가 입력 될때마다 호출되는 method
	func textViewDidChange(_ textView: UITextView) {
		self.validateInputField()
	}
}
