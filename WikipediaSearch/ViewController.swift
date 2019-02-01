//
//  ViewController.swift
//  WikipediaSearch
//
//  Created by nijibox088 on 2019/01/31.
//  Copyright © 2019年 recruit. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SafariServices

class ViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.searchBar.rx.text.orEmpty
            .filter { $0.count >= 2 }
            .map { let urlStr = "https://ja.wikipedia.org/w/api.php?format=json&action=query&list=search&srsearch=\($0)"
                return URL(string: urlStr.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!)!
            }
            .flatMapLatest { URLSession.shared.rx.json(url: $0) }
            .map { self.parseJson($0) }
            .bind(to: tableView.rx.items(cellIdentifier: "Cell")) { index, result, cell in
                cell.textLabel?.text  = result.title
                cell.detailTextLabel?.text = "https://ja.wikipedia.org/w/index.php?curid=\(result.pageid)"
            }
            .disposed(by: disposeBag)
        
        self.tableView.rx.itemSelected.asDriver().drive( onNext:{
            [unowned self] indexPath in
            if let text = self.tableView.cellForRow(at: indexPath)?.detailTextLabel?.text {
                if let url = URL(string: text) {
                    let sc = SFSafariViewController(url: url)
                    self.present(sc, animated: false, completion: {})
                }
                
            }
        
        }).disposed(by: disposeBag)
    }

    func parseJson(_ json: Any) -> [Result] {
        guard let items = json as? [String:Any] else {
            return []
        }
        //print(items)
        var results = [Result]()
        if let queryItems = items["query"] as? [String:Any] {
            if let searchItems = queryItems["search"] as? [[String:Any]] {
                searchItems.forEach {
                    guard let title = $0["title"] as? String,
                        let pageid = $0["pageid"] as? Int else { return }
                    results.append(Result(title: title, pageid: pageid))
                }
            }
        }
        return results
    }
}

struct Result {
    let title: String
    let pageid: Int
}
