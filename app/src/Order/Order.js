import BootstrapTable from "react-bootstrap-table-next";
import { Button, ButtonGroup } from 'react-bootstrap';
import OrderDescription from "./OrderDescription";
import filterFactory, { textFilter } from 'react-bootstrap-table2-filter';
import { Component } from "react";

export default class Order extends Component {
  constructor(props) {
    super(props);
    this.state = {
      orderDescription: -1,
      orders: [],
      numElement: 10
    }

    this.getOrderData()
    this.handleLoadMore = this.handleLoadMore.bind(this)
    this.setOrderDescription = this.setOrderDescription.bind(this)
    this.deleteOrder = this.deleteOrder.bind(this)
  }

  getOrderData() {
    fetch("/api/order/all")
    .then((response) => {
      if (response.ok) {
        return response.json()
      } else {
        response.text().then(text => { alert(text);})
      }
    })
    .then((data) => {
      this.setState({orders: data})
    })
    .catch((error) => {
      console.error("Error fetching data: ", error);
    })
  }

  deleteOrder(id) {
    fetch("/api/order/remove?id=" + id, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      }
    })
    .then((response) => {
      if (response.ok) {
        this.setOrderDescription(-1)
        const orders = this.state.orders
        const index = orders.findIndex((e => e.ID === id))
        orders.splice(index, 1)
        this.setState({
          orders: orders,
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
      this.setState({orderDescription: row.ID})
    },
  };

  columns = [
    { dataField: "ID", text: "Order ID", sort: true, filter: textFilter()},
    { dataField: "TimeCreated", text: "Time Created", sort: true, filter: textFilter()},
    { dataField: "SumPrices", text: "Sum Prices"},
    { dataField: "ID_Customer", text: "Customer ID", filter: textFilter()},
    { dataField: "ID_Employee", text: "Employee ID", filter: textFilter()},
    { dataField: "ID_Ad", text: "CTKM ID", filter: textFilter()}
  ];

  handleLoadMore() {
    this.setState(prevState => ({
      numElement: prevState.numElement * 2
    }));
  }

  setOrderDescription(id) {
    this.setState({
      orderDescription: id
    })
  }
  render() {
    return (
      <div className="popup_container">
        <h1>Order Table</h1>
        <Button className="customButton" variant="success" onClick={() => {this.setOrderDescription(0)}}>Add Order</Button>
        <div className="table-custom">
          <BootstrapTable keyField="id" data={this.state.orders.slice(0, this.state.numElement)} columns={this.columns} rowEvents={this.rowEvents} filter={filterFactory()}/>
        </div>
        <div className="container">
          <ButtonGroup className="me-2">
            <Button variant="success" onClick={() => {this.handleLoadMore()}}>Load More</Button>
          </ButtonGroup>
        </div>
        <div>
          {this.state.orderDescription === -1 ? <p/> : this.state.orderDescription === 0 ?
            <OrderDescription id={this.state.orderDescription} setOrderDescription={this.setOrderDescription} action={'Add'}/> :
            <OrderDescription id={this.state.orderDescription} setOrderDescription={this.setOrderDescription} deleteOrder={this.deleteOrder} action={'Edit'}/>}
        </div>
      </div>
    );
  }
}