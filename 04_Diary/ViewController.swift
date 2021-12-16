//
//  ViewController.swift
//  04_Diary
//
//  Created by Jacob Ko on 2021/12/15.
//

import UIKit

class ViewController: UIViewController {
	@IBOutlet weak var collectionView: UICollectionView!
	
	// diaryList 에 데이터가 추가, 변경, 삭제 될때 마다 Userdefaults 를 통해 저장됨
	private var diaryList = [Diary]() {
		didSet {
			self.saveDiaryList()
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.configureCollectionView()
		self.loadDiaryList()
		// NotificationCenter editDiaryNotification observer
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(editDiaryNotification(_:)),
			name: NSNotification.Name("editDiary"),
			object: nil
		)
		// NotificationCenter isHeart observer
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(heartDiaryNotification(_:)),
			name: NSNotification.Name("heartDiary"),
			object: nil
		)
		// NotificationCenter deleteDiary observer
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(deleteDiaryNotification(_:)),
			name: NSNotification.Name("deleteDiary"),
			object: nil
		)
	}
	
	// Notification editDiary observer selector
	@objc func editDiaryNotification(_ notification: Notification) {
		guard let diary = notification.object as? Diary else { return }
		// 배열을 iteration 해서 전달 받은 uuid 와 같은 값이 배열의 요소에 있는지 확인하기, 있으면 해당 요소의 index를 return 받기
		guard let index = self.diaryList.firstIndex(where: { $0.uuidString == diary.uuidString }) else { return }
		self.diaryList[index] = diary
		self.diaryList = self.diaryList.sorted(by: {
			$0.date.compare($1.date) == .orderedDescending
		})
		self.collectionView.reloadData()
	}
	
	// Notification isHeart observer selector
	@objc func heartDiaryNotification(_ notification: Notification) {
		guard let heartDiary = notification.object as? [String: Any] else { return }
		guard let isHeart = heartDiary["isHeart"] as? Bool else { return }
		guard let uuidString = heartDiary["uuidString"] as? String else { return }
		guard let index = self.diaryList.firstIndex(where: { $0.uuidString == uuidString }) else { return }
		self.diaryList[index].isHeart = isHeart
	}
	
	// Notification deleteDiary observer selector
	@objc func deleteDiaryNotification(_ notification: Notification) {
		guard let uuidString = notification.object as? String else { return }
		guard let index = self.diaryList.firstIndex(where: { $0.uuidString == uuidString }) else { return }
		self.diaryList.remove(at: index)
		self.collectionView.deleteItems(at: [IndexPath(row: index, section: 0)])
	}
	
	
	// 저장된 diaryList 를 FlowLayout() 화면에 구현
	private func configureCollectionView() {
		self.collectionView.collectionViewLayout = UICollectionViewFlowLayout()
		self.collectionView.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
		self.collectionView.delegate = self
		self.collectionView.dataSource = self
	}

	// create Diary 에서 저장된 값이 segueway를 통해서 이동하기 때문에 prepare method 호출
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let writeDiaryViewController = segue.destination as? WriteDiaryViewController {
			writeDiaryViewController.delegate = self
		}
	}
	
	// UserDefaults 에 diaryList 저장하기
	private func saveDiaryList() {
		let date = self.diaryList.map {
			[
				"uuidString": $0.uuidString,
				"title": $0.title,
				"contents": $0.contents,
				"date": $0.date,
				"isHeart": $0.isHeart,
			]
		}
		let userDefaults = UserDefaults.standard
		userDefaults.set(date, forKey: "diaryList")
	}
	
	// UserDefaults 에 저장된 데이터 불러오기
	private func loadDiaryList() {
		let userDefaluts = UserDefaults.standard
		// userDefaults 에서 저장된 데이터 불러올때는 any type 으로 return 되기 때문에 type casting 을 dictonary 형태로 형변환 해야함
		guard let data =  userDefaluts.object(forKey: "diaryList") as? [[String: Any]] else { return }
		self.diaryList = data.compactMap{
			guard let uuidString = $0["uuidString"] as? String else { return nil}
			guard let title = $0["title"] as? String else { return nil}
			guard let contents = $0["contents"] as? String else { return nil}
			guard let date = $0["date"] as? Date else { return nil }
			guard let isHeart = $0["isHeart"] as? Bool else { return nil }
			return Diary(uuidString: uuidString,title: title, contents: contents, date: date, isHeart: isHeart)
		}
		
		// loadDiaryList 가 최신 순으로 정렬되게 sort
		self.diaryList = self.diaryList.sorted(by: {
			$0.date.compare($1.date) == .orderedDescending
		})
	}
	
	// Date type 을 String 으로 바꾸는 method
	private func dateToString(date: Date) -> String {
		let formatter = DateFormatter()
		formatter.dateFormat = "yy년 MM월 dd일(EEEEE)"
		formatter.locale = Locale(identifier: "ko_KR")
		return formatter.string(from: date)
	}
}

// collectionView dateSource delegate
extension ViewController: UICollectionViewDataSource {
	// numberOfSections : 지정된 section 에 표시할 cell 의 갯수를 나타내는 method (다이어리 수만큼 생성되게 함)
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return self.diaryList.count
	}
	
	// cellForItemAt : collection view에 위치되어있는 위치에 표시할 cell 을 요청하는 method
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DiaryCell", for: indexPath) as? DiaryCell else { return UICollectionViewCell() }
		let diary = self.diaryList[indexPath.row]
		cell.titleLabel.text = diary.title
		cell.dateLabel.text = self.dateToString(date: diary.date)
		return cell
	}
}

// collectionView 의 layout 구성
extension ViewController: UICollectionViewDelegateFlowLayout {
	// sizeForItemAt: size 를 설정하는 method 표시할 cell 의 사이즈를 CGSize 로 정의하고, return 해주면 설정한 size 대로 cell 에 표시됨
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		// UIScreen.main.bounds.width 에 아이폰 사이즈 너비에 맞게 조절하고 / 2 해서 한 화면에 2개의 cell 이 나타나게 하며 -20 은 좌우 여백 10 의 합친 값이 20을 빼줘야 됨
		return CGSize(width: (UIScreen.main.bounds.width / 2) - 20, height: 200)
	}
}

// diary 화면에서 일기를 선택하였을때 일기 상세화면으로 이동하고, 일기 상세 내용을 볼 수 있습니다.
extension ViewController: UICollectionViewDelegate {
	// 특정 cell 이 선택 되었음을 알리는 cell 임
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		guard let viewController = self.storyboard?.instantiateViewController(identifier: "DiaryDetailViewController") as? DiaryDetailViewController else { return }
		let diary = self.diaryList[indexPath.row]
		viewController.diary = diary
		viewController.indexPath = indexPath
		// Notification Center 로 대체
		// viewController.delegate = self
		self.navigationController?.pushViewController(viewController, animated: true)
	}
}


extension ViewController: WriteDiaryViewDelegate {
	func didSelectReigster(diary: Diary) {
		self.diaryList.append(diary)
		// DiaryList 저장되고 cell 들이 최신 순으로 정렬되게 sort
		self.diaryList = self.diaryList.sorted(by: {
			$0.date.compare($1.date) == .orderedDescending
		})
		// diaryList 에 새로운 date 가 추가 될때 마다 reload 되게 함
		self.collectionView.reloadData()
	}
}

// 선택된 indexPath 에 따라서 diaryList 가 삭제 되는 extention (NotificationCenter 로 대체됨)
// extension ViewController: DiaryDetailViewDelegate {
// 	func didSelecteDelete(indexPath: IndexPath) {
// 		self.diaryList.remove(at: indexPath.row)
// 		self.collectionView.deleteItems(at: [indexPath])
// 	}
//
	// heart btn 이 눌려진 상태로 전달값을 받아서 viewController 화면에 표시되게 함 (NotificationCenter 로 대체됨)
	// func didSelectHeart(indexPath: IndexPath, isHeart: Bool) {
	// 	self.diaryList[indexPath.row].isHeart = isHeart
	// }
// }
