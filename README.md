# diary-ios-practice

<img width="350" alt="스크린샷" src="https://user-images.githubusercontent.com/28912774/146463434-d3050373-3847-434f-9501-a6959d9817de.gif">

## 기능 상세

- 일기장 탭을 누르면 일기 리스트를 표시할 수 있습니다

- 즐겨찾기 탭을 누르면 즐겨찾기한 일기 리스트를 표시할 수 있습니다

- 일기를 등록, 수정, 삭제, 즐겨찾기 할 수 있습니다

## Check Point !

![image](https://user-images.githubusercontent.com/28912774/146463839-8592e37a-246f-48ea-a57c-d8c967c376b8.png)

### UITabBarController

- 일기장의 tab과 즐겨찾기 tab을 선택하면 각각 다른 화면이 보이게 구현

### UICollectionView

- 일기 list 를 표시하기

### NotificationCenter

- 수정, 삭제 등 event notification observing 하는것을 전달하여 기능 구현

> Describing check point in details in Jacob's DevLog - https://jacobko.info/ios/ios-06/

## Error Check Point

### Delete error issue

![image](https://user-images.githubusercontent.com/28912774/146369957-5d96ec4f-9ab8-482e-80f3-476d7a4103b5.png)

NotificationCenter 로 참조한 data 를 지울때 같은 diaryList 를 참조하기때문에 만약 home 화면의 diary list 에서 즐겨찾기가 되어 있고, 하나는 안되어 있는 상태에서 안되어 있는 것을 지울때 위와 같은 error message 가 표시 됩니다. 왜냐하면 즐겨찾기 에서도 같은 위치의 NotificationCenter 의 indexPath 를 찾기 때문에 즐겨찾기 페이지에는 1개 밖에 없기 때문에 해당이 되지 않게 됩니다 => `Error index out of range`

### Solving Problem

dairy date 를 추가할때 마다, 객체에 특정할 수 있는 고유의 key 값을 설정해서 저장하고, 수정,삭제 시 이 key 값을 참조하여 단순히 list 의 indexPath 로 삭제 하는것이 아니라 key 값을 참조해서 그 데이터를 삭제 해줘야 함 => (`uuid 값 추가`)

- struct 에 uuid String 값 추가

```swift
import Foundation

struct Diary {
	var uuidString: String
	var title: String
	var contents: String
	var date: Date
	var isHeart: Bool
}
```

- diary 가 add 될때 마다 uuid 값 추가하기, edit 모드일때 uuidString 값 참조하기

```swift
// in  WriteDiaryViewController.swift

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
```

- 삭제가 일어날때, indexPath 대신 uuidString 이 전달되게 하기

```swift
// DiaryDetailViewController.swift

@IBAction func tabDeleteBtn(_ sender: UIButton) {
		// indexPath 대신 uuid 값을 불러오기
		// guard let indexPath = self.indexPath else { return }
		guard let uuidString = self.diary?.uuidString else { return }
		// delegate 더이상 필요 없음 (NotificationCenter 로 대체)
		// self.delegate?.didSelecteDelete(indexPath: indexPath)
		NotificationCenter.default.post(
			name: NSNotification.Name("deleteDiary"),
			object: uuidString, // indexPath uuidString 이 전달되게 함
			userInfo: nil)
		self.navigationController?.popViewController(animated: true)
	}

	// tabheartBtn action selector
	@objc func tabHeartBtn() {
		// 즐겨찾기 토글 기능 (on / off 기능)
		guard let isHeart = self.diary?.isHeart else { return }
		// 즐겨찾기 에서도 더이상 indexPath 대신 uuidString 사용
		// guard let indexPath = self.indexPath else { return }

		if isHeart {
			self.heartBtn?.image = UIImage(systemName: "heart")
		} else {
			self.heartBtn?.image = UIImage(systemName: "heart.fill")
		}
		self.diary?.isHeart = !isHeart
		// delegate 으로 보낼경우 1:1 밖에 보낼 수 없기 때문에 NotificationCenter 을 이용해서 값을 보내야지 favorite 에서도 볼 수 있게 됨
		// self.delegate?.didSelectHeart(indexPath: indexPath, isHeart: self.diary?.isHeart ?? false)
		// Notification 에 isHeart 여부 보내기 logic
		NotificationCenter.default.post(
			name: NSNotification.Name("heartDiary"),
			object: [
				"diary" : self.diary,
				"isHeart" : self.diary?.isHeart ?? false,
				"uuidString": diary?.uuidString
			],
			userInfo: nil
		)
	}
```

- UserDefaults 에 저장, 로드할때도 uuidString 추가

```swift
// in ViewController.swift

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
```

- 즐겨찾기 페이지에서도 uuidString 을 가져올 수 있게 추가

```swift
// in FavoriteViewController.swift

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
```

## reference

Jacob's DevLog - [https://jacobko.info/ios/ios-06/](https://jacobko.info/ios/ios-06/)

김종권의 iOS 앱 개발 알아가기 - [https://ios-development.tistory.com/103](https://ios-development.tistory.com/103)

fastcampus - [https://fastcampus.co.kr/dev_online_iosappfinal](https://fastcampus.co.kr/dev_online_iosappfinal)
