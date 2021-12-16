//
//  FavorateViewController.swift
//  04_Diary
//
//  Created by Jacob Ko on 2021/12/16.
//

import UIKit

class FavorateViewController: UIViewController {
	@IBOutlet weak var collectionView: UICollectionView!
	
	
	private var diaryList = [Diary]()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.configureCollectionView()
		self.loadHeartDiaryList()
		
		// NotificationCenter edit observer
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(editDiaryNotification(_:)),
			name: NSNotification.Name("editDiary"),
			object: nil
		)
		// NotificationCenter heart toggle observer
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(heartDiaryNotification(_:)),
			name: NSNotification.Name("heartDiary"),
			object: nil
		)
		// NotificationCenter heart toggle observer
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(deleteDiaryNotification(_:)),
			name: NSNotification.Name("deleteDiary"),
			object: nil
		)
	}
	
	
	// load된 즐겨찾기 데이터를 collectionView 에 표시되게 나타내기
	private func configureCollectionView() {
		self.collectionView.collectionViewLayout = UICollectionViewFlowLayout()
		self.collectionView.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
		self.collectionView.delegate = self
		self.collectionView.dataSource = self
	}
	
	// Date type 을 String 으로 바꾸는 method
	private func dateToString(date: Date) -> String {
		let formatter = DateFormatter()
		formatter.dateFormat = "yy년 MM월 dd일(EEEEE)"
		formatter.locale = Locale(identifier: "ko_KR")
		return formatter.string(from: date)
	}
	
	
	// UserDefaults 에서 즐겨찾기 되어있는 diaryList 만 가져오기 logic
	private func loadHeartDiaryList() {
		let userDefaults = UserDefaults.standard
		guard let data =  userDefaults.object(forKey: "diaryList") as? [[String: Any]] else { return }
		self.diaryList = data.compactMap {
			guard let uuidString = $0["title"] as? String else { return nil }
			guard let title = $0["title"] as? String else { return nil }
			guard let contents = $0["contents"] as? String else { return nil }
			guard let date = $0["date"] as? Date else { return nil }
			guard let isHeart = $0["isHeart"] as? Bool else { return nil }
			return Diary(uuidString: uuidString, title: title, contents: contents, date: date, isHeart: isHeart)
			// fliter 함수를 사용해서 즐겨찾기 되어 있는 부분만 가져오고, 날짜가 최신순으로 오게끔 정렬하기
		}.filter({
			$0.isHeart == true
		}).sorted(by: {
			$0.date.compare($1.date) == .orderedDescending
		})
	}
	
	// 수정이 일어날때 호출되는 selector
	@objc func editDiaryNotification(_ notification: Notification) {
		guard let diary = notification.object as? Diary else { return }
		guard let index = self.diaryList.firstIndex(where: { $0.uuidString == diary.uuidString }) else { return }
		self.diaryList[index] = diary
		self.diaryList = self.diaryList.sorted(by: {
			$0.date.compare($1.date) == .orderedDescending
		})
		self.collectionView.reloadData()
	}
	
	// isHeart toggle 일어날때 호출되는 selector
	@objc func heartDiaryNotification(_ notification: Notification) {
		guard let heartDiary = notification.object as? [String: Any] else { return }
		guard let dairy = heartDiary["diary"] as? Diary else { return }
		guard let isHeart = heartDiary["isHeart"] as? Bool else { return }
		guard let uuidString = heartDiary["uuidString"] as? String else { return }

		if isHeart { // 즐겨찾기가 된 diaryList 에 append 추가해줌
			self.diaryList.append(dairy)
			self.diaryList = self.diaryList.sorted(by: {
				$0.date.compare($1.date) == .orderedDescending
			})
			self.collectionView.reloadData()
		} else { // 즐겨찾기가 해재되면 diratyList 와 deleteItems 에도 삭제함
			guard let index = self.diaryList.firstIndex(where: { $0.uuidString == uuidString }) else { return }
			self.diaryList.remove(at: index)
			self.collectionView.deleteItems(at: [IndexPath(row: index, section: 0)])
		}
	}
	
	// delete notification selector
	@objc func deleteDiaryNotification(_ notification: Notification) {
		guard let uuidString = notification.object as? String else { return }
		guard let index = self.diaryList.firstIndex(where: { $0.uuidString == uuidString }) else { return }
		self.diaryList.remove(at: index)
		self.collectionView.deleteItems(at: [IndexPath(row: index, section: 0)])
	}
}

// collectionView 의 dataSource extension
extension FavorateViewController: UICollectionViewDataSource {
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return self.diaryList.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HeartCell", for: indexPath) as? HeartCell else { return UICollectionViewCell()}
		let diary = self.diaryList[indexPath.row]
		cell.titleLabel.text = diary.title
		cell.dateLabel.text = self.dateToString(date: diary.date)
		return cell
	}
}

// UICollectionViewDelegateFlowLayout 의 delegate extension : layout 구성
extension FavorateViewController: UICollectionViewDelegateFlowLayout {
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return CGSize(width: UIScreen.main.bounds.width - 20, height: 80)
	}
}

// DetailPage로 이동 하는 delegate
extension FavorateViewController: UICollectionViewDelegate {
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		guard let viewController = self.storyboard?.instantiateViewController(identifier: "DiaryDetailViewController") as? DiaryDetailViewController else { return }
		let diary = self.diaryList[indexPath.row]
		viewController.diary = diary
		viewController.indexPath = indexPath
		self.navigationController?.pushViewController(viewController, animated: true)
	}
}
