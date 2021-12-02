import BootstrapTable from "react-bootstrap-table-next";
import { Button, ButtonGroup } from 'react-bootstrap';
import PIODescription from "./PIODescription";
import filterFactory from 'react-bootstrap-table2-filter';
import { Component } from "react";
import { DataManager, Query } from "@syncfusion/ej2-data";
import HotProduct from "./HotProduct"

export default class ProductInOrder extends Component {
  constructor(props) {
    super(props);
    this.state = {
      pioDescription_1: -1,
      pioDescription_2: -1,
      originalPIO: [],
      pio: [],
      numElement: 10,
      hotProduct: false
    }

    this.getPIOData()
    this.handleLoadMore = this.handleLoadMore.bind(this)
    this.setPIODescription = this.setPIODescription.bind(this)
    this.deletePIO = this.deletePIO.bind(this)
    this.searchByOrderID = this.searchByOrderID.bind(this)
    this.enableHotProduct = this.enableHotProduct.bind(this)
    this.disableHotProduct = this.disableHotProduct.bind(this)
  }

  getPIOData() {
    fetch("/api/order/allpio")
    .then((response) => {
      if (response.ok) {
        return response.json()
      } else {
        response.text().then(text => { alert(text);})
      }
    })
    .then((data) => {
      this.setState({pio: data, originalPIO: data})
    })
    .catch((error) => {
      console.error("Error fetching data: ", error);
    })
  }

  deletePIO(id_1, id_2) {
    fetch("/api/order/removepio?id_order="+id_1+"&id_prod="+id_2, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      }
    })
    .then((response) => {
      if (response.ok) {
        this.setPIODescription(-1, -1)
        const pio = this.state.pio
        const index = pio.findIndex((e => (e.ID_Order === id_1 && e.ID_Prod === id_2)))
        pio.splice(index, 1)
        this.setState({
          pio: pio,
        })
      } else {
        response.text().then(text => { alert(text) })
      }
    })
    .catch((error) => {
      console.error("Error detect: ", error);
    })
  }

  rowEvents = {
    onClick: (e, row, rowIndex) => {
      this.setState({pioDescription_1: row.ID_Order, pioDescription_2: row.ID_Prod})
    },
  };

  columns = [
    { dataField: "ID_Order", text: "Order ID", sort: true},
    { dataField: "ID_Prod", text: "Product ID", sort: true},
    { dataField: "Price", text: "Price"},
    { dataField: "Quantity", text: "Quantity"}
  ];

  handleLoadMore() {
    this.setState(prevState => ({
      numElement: prevState.numElement * 2
    }));
  }

  setPIODescription(id_1, id_2) {
    this.setState({
        pioDescription_1: id_1,
        pioDescription_2: id_2
    })
  }

  // Filter
  searchByOrderID(event) {
    let value = event.target.value;
    let data = new DataManager(this.state.pio).executeLocal(new Query().where("ID_Order", "startswith", value, true));
    if (!value) {
        this.setState({
            pio: this.state.originalPIO
        });
    }
    else {
        this.setState({
            pio: data
        });
    }
  }

  enableHotProduct() {
    this.setState({
      hotProduct: true
    })
    console.log(this.state.hotProduct)
  }
  
  disableHotProduct() {
    this.setState({
      hotProduct: false
    })
  }

  render() {
    return (
      <div className="popup_container">
        <h1>Products in Order Table</h1>
        <Button className="customButton" variant="success" onClick={() => {this.setPIODescription(0, 0)}}>Add Product in Order</Button>
        <Button className="customButton" style={{marginLeft: '1vw'}} onClick={() => {this.enableHotProduct()}}>Get Hot Product</Button>
        <div>
        <input className="input-search" style={{marginTop: '1vh'}} type="text" title="Type in a name" placeholder="Lọc Order ID" onKeyUp={this.searchByOrderID}/>
        </div>
        <div className="table-custom">
          <BootstrapTable keyField="id" data={this.state.pio.slice(0, this.state.numElement)} columns={this.columns} rowEvents={this.rowEvents} filter={filterFactory()}/>
        </div>
        <div className="container">
          <ButtonGroup className="me-2">
            <Button variant="success" onClick={() => {this.handleLoadMore()}}>Load More</Button>
          </ButtonGroup>
        </div>
        <div>
          {this.state.pioDescription_1 === -1 ? <p/> : this.state.pioDescription_1 === 0 ?
            <PIODescription id_order={this.state.pioDescription_1} id_prod={this.state.pioDescription_2} setPIODescription={this.setPIODescription} action={'Add'}/> :
            <PIODescription id_order={this.state.pioDescription_1} id_prod={this.state.pioDescription_2} setPIODescription={this.setPIODescription} deletePIO={this.deletePIO} action={'Edit'}/>}
        </div>
        <div>
          {this.state.hotProduct ?
            <HotProduct disableHotProduct={this.disableHotProduct}/> :
            <p/>}
        </div>
      </div>
    );
  }
}