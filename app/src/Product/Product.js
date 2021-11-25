import BootstrapTable from "react-bootstrap-table-next";

export default function Product() {
  const products = [];
  const columns = [
    {
      dataField: "id",
      text: "Product ID",
      sort: true,
    },
    {
      dataField: "name",
      text: "Product Name",
      sort: true,
    },
    {
      dataField: "price",
      text: "Product Price",
    },
  ];

  return (
    <div>
      <div className="table-custom">
         {/* https://react-bootstrap-table.github.io/react-bootstrap-table2/docs/about.html  */}
        <BootstrapTable keyField="id" data={products} columns={columns} />
      </div>
    </div>
  );
}
